//
//	DDExpandableButton.m
//	https://github.com/ddebin/DDExpandableButton
//


//
//	ARC Helper
//
//	Version 2.2
//
//	Created by Nick Lockwood on 05/01/2012.
//	Copyright 2012 Charcoal Design
//
//	Distributed under the permissive zlib license
//	Get the latest version from here:
//
//	https://gist.github.com/1563325
//

#import <Availability.h>
#undef ah_retain
#undef ah_dealloc
#undef ah_autorelease
#undef ah_dealloc
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_release self
#define ah_autorelease self
#define ah_dealloc self
#else
#define ah_retain retain
#define ah_release release
#define ah_autorelease autorelease
#define ah_dealloc dealloc
#endif

//	ARC Helper ends


#import <QuartzCore/CALayer.h>
#import <tgmath.h>
#import "DDExpandableButton.h"


#pragma mark - Custom UIImageView Class


@interface DDExpandableButtonCustomUILabel : UILabel <DDExpandableButtonViewSource>

@end

@implementation DDExpandableButtonCustomUILabel

- (CGSize)defaultFrameSize
{
    return [self.text sizeWithAttributes:@{NSFontAttributeName : self.font}];
}

@end


#pragma mark - Custom UILabel Class


@interface DDExpandableButtonCustomUIImageView : UIImageView <DDExpandableButtonViewSource>

@end

@implementation DDExpandableButtonCustomUIImageView

- (CGSize)defaultFrameSize
{
	return self.image.size;
}

@end


#pragma mark - DDExpandableButton Class


@interface DDExpandableButton (private)

- (CGRect)currentFrameRect;
- (CGRect)shrunkFrameRect;
- (CGRect)expandedFrameRect;
- (DDView *)getViewFrom:(id)obj;

@end


@implementation DDExpandableButton

@synthesize selectedItem;
@synthesize expanded;
@synthesize toggleMode;
@synthesize useAnimation;
@synthesize borderColor;
@synthesize textColor;
@synthesize labelFont;
@synthesize unSelectedLabelFont;
@synthesize timeout;
@synthesize horizontalPadding;
@synthesize verticalPadding;
@synthesize borderWidth;
@synthesize innerBorderWidth;
@synthesize labels;


#pragma mark Default Values

#define DEFAULT_USE_ANIMATION	YES
#define DEFAULT_DISABLED_ALPHA	0.5f
#define DEFAULT_TIMEOUT			4.0f
#define DEFAULT_ALPHA			0.8f
#define DEFAULT_BORDER_WIDTH	1.0f
#define DEFAULT_INNER_WIDTH		1.0f
#define DEFAULT_HORI_PADDING	12.0f
#define DEFAULT_VERT_PADDING	7.0f
#define DEFAULT_BORDER_WHITE	0.0f
#define DEFAULT_BORDER_ALPHA	1.0f
#define DEFAULT_BKG_WHITE		1.0f
#define DEFAULT_BKG_ALPHA		0.4f
#define DEFAULT_FONT			[UIFont boldSystemFontOfSize:14.0f]
#define DEFAULT_UNSELECTED_FONT nil


#pragma mark - Init Methods

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self != nil)
	{
		// Flash Button like parameters
		expanded = NO;
		maxHeight = 0;
		useAnimation = DEFAULT_USE_ANIMATION;
		borderWidth = DEFAULT_BORDER_WIDTH;
		innerBorderWidth = DEFAULT_INNER_WIDTH;
		horizontalPadding = DEFAULT_HORI_PADDING;
		verticalPadding = DEFAULT_VERT_PADDING;
		timeout = DEFAULT_TIMEOUT;

		[self addTarget:self action:@selector(chooseLabel:forEvent:) forControlEvents:UIControlEventTouchUpInside];

		self.borderColor = [UIColor colorWithWhite:DEFAULT_BORDER_WHITE alpha:DEFAULT_BORDER_ALPHA];
		self.textColor = borderColor;
		self.labelFont = DEFAULT_FONT;
		self.unSelectedLabelFont = DEFAULT_UNSELECTED_FONT;

		self.backgroundColor = [UIColor colorWithWhite:DEFAULT_BKG_WHITE alpha:DEFAULT_BKG_ALPHA];
		self.alpha = DEFAULT_ALPHA;
		self.opaque = YES;
	}
	return self;
}

- (id)initWithPoint:(CGPoint)point leftTitle:(id)leftTitle buttons:(NSArray *)buttons
{
	self = [self initWithFrame:CGRectMake(point.x, point.y, 0, 0)];
	if (self != nil)
	{
		[self setLeftTitle:leftTitle];
		[self setButtons:buttons];
		[self updateDisplay];
	}
	return self;
}


#pragma mark - Dealloc

#if !__has_feature(objc_arc)
- (void)dealloc
{
	[leftTitleView release];
	[borderColor release];
	[textColor release];
	[labelFont release];
	[unSelectedLabelFont release];
	[labels release];
	[super dealloc];
}
#endif


#pragma mark - Parameters Methods

- (void)disableTimeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shrinkButton) object:nil];
	timeout = 0;
}

- (void)setLeftTitle:(id)leftTitle
{
	[leftTitleView removeFromSuperview];
	[leftTitleView ah_release];
	leftTitleView = nil;

	if (leftTitle != nil)
	{
		leftTitleView = [[self getViewFrom:leftTitle] ah_retain];
		[self addSubview:leftTitleView];
	}
}

- (void)setButtons:(NSArray *)buttons
{
	// Remove all existing labels
	for (DDView *v in labels)
	{
		[v removeFromSuperview];
	}
	[labels ah_release];

	NSMutableArray *_labels = [NSMutableArray arrayWithCapacity:[buttons count]];
	for (NSObject *button in buttons)
	{
		DDView *v = [self getViewFrom:button];
		v.alpha = 0;
		[self addSubview:v];
		[_labels addObject:v];
	}
	labels = [_labels ah_retain];
}

- (void)updateDisplay
{
	// maxHeight update
	maxWidth = 0;
	maxHeight = (leftTitleView != nil)?([leftTitleView defaultFrameSize].height + verticalPadding * 2.0f):0;
	for (DDView *v in labels)
	{
		maxHeight = MAX(maxHeight, [v defaultFrameSize].height + verticalPadding * 2.0f);
		maxWidth = MAX(maxWidth, [v defaultFrameSize].width);
	}

	// borderWidth update
	for (DDView *v in labels)
	{
		v.layer.borderWidth = innerBorderWidth;
	}

	cornerAdditionalPadding = round(maxHeight / 2.2f) - borderWidth - horizontalPadding;

	leftWidth = cornerAdditionalPadding;
	if (leftTitleView != nil) leftWidth += horizontalPadding + [leftTitleView defaultFrameSize].width + ((innerBorderWidth == 0)?horizontalPadding:0);

	self.layer.borderWidth	= borderWidth;
	self.layer.borderColor	= borderColor.CGColor;
	self.layer.cornerRadius = round(maxHeight / 2.0f);

	[self setSelectedItem:0 animated:NO];
}


#pragma mark - Frame Rect Methods

- (CGRect)shrunkFrameRect
{
	if (toggleMode)
	{
		return CGRectMake(self.frame.origin.x, self.frame.origin.y, (cornerAdditionalPadding + horizontalPadding) * 2 + maxWidth, maxHeight);
	}
	else
	{
		DDView *currentLabel = [labels objectAtIndex:selectedItem];
		return CGRectMake(self.frame.origin.x, self.frame.origin.y, currentLabel.frame.origin.x + currentLabel.frame.size.width + cornerAdditionalPadding, maxHeight);
	}
}

- (CGRect)expandedFrameRect
{
	if (toggleMode)
	{
		return [self shrunkFrameRect];
	}
	else
	{
		DDView *lastLabel = [labels lastObject];
		return CGRectMake(self.frame.origin.x, self.frame.origin.y, lastLabel.frame.origin.x + lastLabel.frame.size.width + cornerAdditionalPadding, maxHeight);
	}
}

- (CGRect)currentFrameRect
{
	if (expanded)
	{
		return [self expandedFrameRect];
	}
	else
	{
		return [self shrunkFrameRect];
	}
}


#pragma mark - Animation Methods

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	self.alpha = enabled?1:DEFAULT_DISABLED_ALPHA;
}

- (void)shrinkButton
{
	[self setExpanded:NO animated:useAnimation];
}

- (void)setExpanded:(BOOL)_expanded
{
	[self setExpanded:_expanded animated:NO];
}

- (void)setExpanded:(BOOL)_expanded animated:(BOOL)animated
{
	expanded = _expanded;

	if (animated)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.2f];
	}

	// set labels appearance

	if (expanded)
	{
		NSUInteger i = 0;
		CGFloat x = leftWidth;
		for (DDView *v in labels)
		{
			if (i != selectedItem)
			{
				if ([v isKindOfClass:[DDExpandableButtonCustomUILabel class]])
				{
					[(DDExpandableButtonCustomUILabel *)v setFont:((unSelectedLabelFont != nil)?unSelectedLabelFont:labelFont)];
				}
				if ([v respondsToSelector:@selector(setHighlighted:)])
				{
					[v setHighlighted:NO];
				}
			}
			else if ([v respondsToSelector:@selector(setHighlighted:)])
			{
				[v setHighlighted:YES];
			}

			CGRect labelRect = CGRectMake(x, 0, [v defaultFrameSize].width + horizontalPadding * 2, maxHeight);
			x += labelRect.size.width - v.layer.borderWidth;
			v.frame = labelRect;
			v.alpha = 1;

			if ((i > 0) && (i < ([labels count] - 1)) && (v.layer.borderWidth > 0))
			{
				v.layer.borderColor = borderColor.CGColor;
			}

			i++;
		}

		if (timeout > 0)
		{
			[self performSelector:@selector(shrinkButton) withObject:nil afterDelay:timeout];
		}
	}
	else
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shrinkButton) object:nil];

		NSUInteger i = 0;
		CGFloat selectedWidth = 0;
		for (DDView *v in labels)
		{
			if ([v isKindOfClass:[DDExpandableButtonCustomUILabel class]])
			{
				[(DDExpandableButtonCustomUILabel *)v setFont:labelFont];
				[(DDExpandableButtonCustomUILabel *)v setTextColor:textColor];
			}
			if ([v respondsToSelector:@selector(setHighlighted:)])
			{
				[v setHighlighted:(i == selectedItem)];
			}

			CGRect r = CGRectZero;
			r.size.height = maxHeight;
			if (i < selectedItem)
			{
				r.origin.x = leftWidth;
				v.alpha = 0;
			}
			else if (i == selectedItem)
			{
				r.size.width = [v defaultFrameSize].width + horizontalPadding * 2;
				r.origin.x = leftWidth;
				selectedWidth = r.size.width;
				v.alpha = 1;
			}
			else if (i > selectedItem)
			{
				r.origin.x = leftWidth + selectedWidth;
				v.alpha = 0;
			}
			v.layer.borderColor = [borderColor colorWithAlphaComponent:0].CGColor;
			v.frame = r;

			i++;
		}
	}

	// set title frames
	leftTitleView.frame = CGRectMake(cornerAdditionalPadding + horizontalPadding, 0, [leftTitleView defaultFrameSize].width, maxHeight);

	// set whole frame
	[self setFrame:[self currentFrameRect]];

	if (animated)
	{
		[UIView commitAnimations];
	}
}

- (void)setSelectedItem:(NSUInteger)selected
{
	[self setSelectedItem:selected animated:NO];
}

- (void)setSelectedItem:(NSUInteger)selected animated:(BOOL)animated
{
	BOOL notify = (selectedItem != selected);

	selectedItem = selected;

	[self setExpanded:NO animated:animated];

	if (notify)
	{
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}


#pragma mark - UIButton UIControlEventTouchUpInside target

- (void)chooseLabel:(id)sender forEvent:(UIEvent *)event
{
	if (toggleMode)
	{
		[self setSelectedItem:((selectedItem + 1) % [labels count])];
	}
	else if (!expanded)
	{
		[self setExpanded:YES animated:useAnimation];
	}
	else
	{
		BOOL inside = NO;

		NSUInteger i = 0;
		for (DDView *v in labels)
		{
			if ([v pointInside:[[[event allTouches] anyObject] locationInView:v] withEvent:event])
			{
				inside = YES;
				break;
			}
			i++;
		}

		if (inside)
		{
			[self setSelectedItem:i animated:useAnimation];
		}
		else
		{
			[self setSelectedItem:selectedItem animated:useAnimation];
		}
	}
}


#pragma mark - Utilities

- (DDView *)getViewFrom:(id)obj
{
	if ([obj isKindOfClass:[NSString class]])
	{
		DDExpandableButtonCustomUILabel *v = [[DDExpandableButtonCustomUILabel alloc] init];
		v.font = labelFont;
		v.textColor = textColor;
		v.backgroundColor = [UIColor clearColor];
		v.textAlignment = NSTextAlignmentCenter;
		v.opaque = YES;
		v.text = obj;
		return [v ah_autorelease];
	}
	else if ([obj isKindOfClass:[UIImage class]])
	{
		DDExpandableButtonCustomUIImageView *v = [[DDExpandableButtonCustomUIImageView alloc] initWithImage:obj];
		v.backgroundColor = [UIColor clearColor];
		v.opaque = YES;
		v.contentMode = UIViewContentModeCenter;
		v.clipsToBounds = YES;
		return [v ah_autorelease];
	}
	else if (obj == nil)
	{
		return nil;
	}
	else
	{
		NSAssert([obj isKindOfClass:[UIView class]], @"obj must be an UIView class !");
		NSAssert([obj conformsToProtocol:@protocol(DDExpandableButtonViewSource)], @"obj must implement protocol DDExpandableButtonViewSource !");
		return obj;
	}
}

@end
