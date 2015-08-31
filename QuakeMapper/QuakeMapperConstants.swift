//
//  QuakeMapperConstants.swift
//  QuakeMapper
//
//  Created by Paul Miller on 13/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation

extension QuakeMapperClient {
    
    //MARK: - Constants
    
    struct Constants {
        
        //MARK: API Keys
        
        static let WebcamsTravelDevID     = "cca71e67c2ff47a553d0d69ef9f730bc"
        
        //MARK: URLs
        static let BaseTwitterURL         = "https://api.twitter.com"
        static let BaseWebcamsTravelURL   = "http://api.webcams.travel/rest"
        
        //Realtime feed of all earthquakes > magnitude 4.5 in the past 7 days. Updates every 5 minutes.
        static let USGS7DayEarthquakeURL  = "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson"
        
        //Realtime feed of all earthquakes > magnitude 4.5 in the past 30 days. Updates every 15 minutes.
        static let USGS30DayEarthquakeURL = "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.geojson"
    }
    
    //MARK: - Methods
    
    struct Methods {
        
        //MARK: Twitter
        static let Search      = "/1.1/search/tweets.json"
        static let BearerToken = "/oauth2/token"
        
        //MARK: Webcams.Travel
        //None.
        
        //MARK: USGS Earthquake Service
        //None.
    }
    
    //MARK: - URL Keys
    
    struct TwitterURLKeys {
        
        static let Query        = "q"
        static let Geocode      = "geocode"
        static let Count        = "count"
        static let Until        = "until"
        static let Since        = "since"
        static let UserID       = "id"
    }
    
    struct WebcamsTravelURLKeys {
        
        static let Method       = "method"
        static let DeveloperID  = "devid"
        static let Format       = "format"
        static let Latitude     = "lat"
        static let Longitude    = "lng"
        static let Radius       = "radius"
        static let Unit         = "unit"
        static let PerPage      = "per_page"
        static let Page         = "page"
        static let Query        = "query"
        static let SouthWestLat = "sw_lat"
        static let SouthWestLon = "sw_lng"
        static let NorthEastLat = "ne_lat"
        static let NorthEastLon = "ne_lng"
        static let Zoom         = "zoom"
        static let MapAPI       = "mapapi"
    }
    
    //MARK: - URL Values
    
    struct WebcamsTravelURLValues {
    
        //MARK: WebcamsTravel methods
        static let ListNearby   = "wct.webcams.list_nearby"
        static let MapBBox      = "wct.map.bbox"
        static let SearchByTags = "wct.search.tags"
        
        //MARK: WebcamsTravel parameter values
        static let JSON         = "json"
        static let Degrees      = "deg"
        static let KM           = "km"
        static let Miles        = "mi"
    }
    
    //MARK: - HTTP Header Field Keys
    
    struct HTTPHeaderFieldKeys {
        
        static let Accept        = "Accept"
        static let ContentType   = "Content-Type"
        
        //MARK: Twitter
        static let Authorization = "Authorization"
        
    }
    
    //MARK: - HTTP Header Field Values
    
    struct HTTPHeaderFieldValues {
        
        static let TwitterAuthContentType = "application/x-www-form-urlencoded;charset=UTF-8"
        static let TwitterAuthBasic       = "Basic"
        static let TwitterAuthBearer      = "Bearer"
    }
    
    //MARK: - HTTP Body Keys
    
    struct TwitterHTTPBodyKeys {
        
        static let GrantType = "grant_type"
    }
    
    //MARK: - HTTP Body Values
    
    struct TwitterHTTPBodyValues {
        
        static let ClientCredentials = "client_credentials"
    }
    
    //MARK: - JSON Response Keys
    
    struct TwitterJSONResponseKeys {
        
        static let TokenType   = "token_type"
        static let AccessToken = "access_token"
        static let Statuses    = "statuses"
        static let Error       = "error"
        static let Errors      = "errors"
        static let Code        = "code"
        static let Label       = "label"
        static let Message     = "message"
    }
    
    struct WebcamsTravelJSONResponseKeys {
    
        static let Status         = "status"
        static let Webcams        = "webcams"
        static let Count          = "count"
        static let Page           = "page"
        static let PerPage        = "per_page"
        static let Webcam         = "webcam"
        static let WebcamID       = "webcamid"
        static let Title          = "title"
        static let URL            = "url"
        static let URLMobile      = "url_mobile"
        static let Latitude       = "latitude"
        static let Longitude      = "longitude"
        static let Timelapse      = "timelapse"
        static let Available      = "available"
        static let FormatMP4      = "format_mp4"
        static let FormatWebM     = "format_webm"
        static let LinkEmbedDay   = "link_embed_day"
        static let TimezoneOffset = "timezone_offset"
        static let Active         = "active"
        static let IconURL        = "icon_url"
        static let ThumbnailURL   = "thumbnail_url"
        static let ToenailURL     = "toenail_url"
        static let PreviewURL     = "preview_url"
        static let Error          = "error"
        static let Code           = "code"
        static let Description    = "description"
    }
    
    struct USGSJSONResponseKeys {
    
        static let Title       = "title"
        static let Status      = "status"
        static let Count       = "count"
        static let Features    = "features"
        static let Properties  = "properties"
        static let Magnitude   = "mag"
        static let PlaceText   = "place"
        static let Time        = "time"
        static let Timezone    = "tz"
        static let URL         = "url"
        static let Geometry    = "geometry"
        static let Coordinates = "coordinates"
        static let ID          = "id"
        static let BBox        = "bbox"
    }
    
    struct CommonJSONResponseKeys {
    
        static let Error = "error"
    }
    
    //MARK: - Website Enum
    
    enum Website {
        
        case WebcamsTravel
        case USGSEarthquake
        case Twitter
        
        //MARK: Helper functions
        
        //Return base URL by website.
        func baseURL() -> String {
            
            switch self {
            case .WebcamsTravel:
                return Constants.BaseWebcamsTravelURL
            case .USGSEarthquake:
                return Constants.USGS30DayEarthquakeURL
            case .Twitter:
                return Constants.BaseTwitterURL
            }
        }
        
        //Add HTTP header field values by website for GET request.
        func addHTTPHeaderFieldKeysForGETRequest(request: NSMutableURLRequest) -> NSMutableURLRequest {
            
            switch self {
            case .WebcamsTravel:
                return request
            case .USGSEarthquake:
                return request
            case .Twitter:
                let bearerValue = HTTPHeaderFieldValues.TwitterAuthBearer + " " + sharedInstance.twitterBearerToken!
                request.addValue(bearerValue, forHTTPHeaderField: HTTPHeaderFieldKeys.Authorization)
                return request
            }
        }
        
        //Add HTTP header field values by website for POST request.
        func addHTTPHeaderFieldKeysForPOSTRequest(request: NSMutableURLRequest) -> NSMutableURLRequest {
            
            switch self {
            case .WebcamsTravel:
                return request
            case .USGSEarthquake:
                return request
            case .Twitter:
                let authValue = HTTPHeaderFieldValues.TwitterAuthBasic + " " + QuakeMapperClient.getBase64TwitterAuthValue()
                request.addValue(authValue, forHTTPHeaderField: HTTPHeaderFieldKeys.Authorization)
                request.addValue(HTTPHeaderFieldValues.TwitterAuthContentType, forHTTPHeaderField: HTTPHeaderFieldKeys.ContentType)
                return request
            }
        }
        
        //Add HTTP header field values by website for PUT request.
        func addHTTPHeaderFieldKeysForPUTRequest(request: NSMutableURLRequest) -> NSMutableURLRequest {
            
            switch self {
            case .WebcamsTravel:
                return request
            case .USGSEarthquake:
                return request
            case .Twitter:
                return request
            }
        }
        
        //Add HTTP header field values by website for DELETE request.
        func addHTTPHeaderFieldKeysForDELETERequest(request: NSMutableURLRequest) -> NSMutableURLRequest {
            
            switch self {
            case .WebcamsTravel:
                return request
            case .USGSEarthquake:
                return request
            case .Twitter:
                return request
            }
        }
    }
}
