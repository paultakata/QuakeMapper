README.md

Project 5 of Udacity iOS Nanodegree - QuakeMapper

Paul Miller 31/08/2015

***
*** General Information ***
***

QuakeMapper shows recent significant earthquakes around the world, allows the
user to check Tweets made about those earthquakes, and view nearby webcams.

QuakeMapper fetches the last 30 days of earthquakes greater than magnitude 4.5
from the US Geological Survey, parses the data and shows the results on a map
with different colours for different earthquake strengths.

The user can choose whether the map displays all the available earthquakes,
only those from the last week or those from a particular day by using a
customised slider.

Tapping on an earthquake zooms the map in, and fetches any nearby webcams
from www.webcams.travel. An image from each webcam is downloaded for its
annotation on the map. The "Return to previous zoom" button moves the map
back to the overview.

The earthquake's callout view has two buttons, one to show a table view of
related tweets, if available, and one to show a collection view of nearby
webcams. It is also possible to tap on a webcam directly from the map. This
will open a web view showing the webcam's web page.

The second tab on the main screen shows a table view of the earthquake data,
sorted most recent first. The table view shows the magnitude, time and
location of the earthquakes, along with a small map snapshot of the location.
The earthquake data is shown in two sections, "Recent Quakes" being those
younger than one week old, and "Older Quakes" showing the remainder. Tapping
on an earthquake here will show the table view of related Tweets, with a
second tab to access the webcam collection view.

Tapping on a Tweet opens a larger view of that Tweet, tapping on this will
open it in a web view.

Most screens also have a refresh button in the top left corner.

***
*** Design Rationale ***
***

My primary goal in writing this app was to be able to meet the Rubric and
Specification of Project 5 as best as I could. I specifically looked for APIs
that were free to use, actively maintained and searchable by location. This
significantly limited my choices, but this limitation helped in my process of
choosing which ones to use.

Because two of my chosen APIs are time-limited: the USGS feed and Twitter,
I incorporated that into the design of my app. Earthquakes are sorted into
"Recent" and "Older", to separate which ones are possible to search for
Tweets, and the View by Day function is limited to the past 30 days.

All the earthquakes, Tweets and webcams the app downloads are persisted in
Core Data. I chose to base the model around the earthquake, so each
Earthquake can have multiple Tweets and multiple Webcams associated with it.
Luckily for me, Twitter has made their TWTRTweet objects NSCoding compliant,
so persisting them in Core Data is easy! The Earthquake and Webcam objects
required a bit more effort to persist, mainly in retrieving their properties
from the received JSON data.

Both the Core Data stack and the networking code are in their own classes.
This follows the methodology introduced in the course. My networking code
contains a few methods that are currently unused, I left them in there to
make it easier to extend the app in the future. I also included the code to
get map snapshots in my networking client even though it technically doesn't
use it. I felt that since it downloads information from the internet it was
better there than anywhere else.

***
*** Notes ***
***

1. External frameworks.

QuakeMapper uses Fabric and TwitterKit, both from Twitter. This is to manage
the guest login necessary to access Twitter's search API, and to streamline
usage of the API itself.

2. Known limitations.

The USGS feed only goes back 30 days, and Twitter's search function currently
only goes back 7 days. This limits the amount of available historical data.

Webcams.travel has a large number of webcams available to search, but many
areas unfortunately still do not have any.

TwitterKit currently has a bug whereby URLs in Tweets are not highlighted and
therefore they cannot be selected by the user. My workaround for this is to
allow the tweet to be displayed as a web page on a subsequent screen: the user
can tap on URLs there.
