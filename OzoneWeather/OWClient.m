//
//  OWClient.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "TFHpple.h"
#import "OWClient.h"
#import "OWCondition.h"
#import "OWDailyForecast.h"
#import "OWOzoneLevel.h"

@interface OWClient ()

@property (nonatomic,strong) NSURLSession *session;

- (RACSignal *)fetchJSONFromURL:(NSURL *)url;
- (RACSignal *)fetchHTMLFromURL:(NSURL *)url;

@end

@implementation OWClient

-(id)init {
    if (self = [super init]){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

-(RACSignal *)fetchJSONFromURL:(NSURL *)url {
    
    NSLog(@"Fetching: %@", url.absoluteString);
    
    // factory method:  creates signal for other objects to use
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // will fetch data to parse later
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Handle session here
            if (! error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (! jsonError) {
                    [subscriber sendNext:json];
                } else {
                    [subscriber sendError:jsonError];
                }
            } else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        // will start the request once there is a subscriber
        [dataTask resume];
        
        // include a disposable object to handle cleanup
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        // side effect:  log errors
        NSLog(@"%@",error);
    }];
}

//TODO:  there's a lot of repetition in the next three methods. The things that change are the url strings, the model to return, and whether or not the data is a single dictionary (current conditions) or an array (hourly or daily forecasts). These could be abstracted out of a single fetch method.  ... also, errors in the MTLJSONAdaptor are not handled. This should change!

-(RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate {
    // create the weather data url request string
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the RACSignal, and map the results  from a json object (dictionary) to an instance of OWCondition using the adapter. whew.
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        return [MTLJSONAdapter modelOfClass:[OWCondition class] fromJSONDictionary:json error:nil];
    }];
}

-(RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    // create the weather data url request string
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the RACSignal,
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        
        //and collect the results in an sequence
        RACSequence *list = [json[@"list"] rac_sequence];
        
        //and map the sequence elements
        return [[list map:^(NSDictionary *item){
            //from json objects to an array OWConditions objects using the adapter. whew.
            return [MTLJSONAdapter modelOfClass:[OWCondition class] fromJSONDictionary:item error:nil];
        }] array];
        
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Use the generic fetch method and map results to convert into an array of Mantle objects
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // build a sequence from the lst of raw JSON
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Use a function to map results from JSON to Mantle objects
        return [[list map:^(NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[OWDailyForecast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}

#pragma-mark ======   TEMIS Ozone Functions ============
-(RACSignal *)fetchHTMLFromURL:(NSURL *)url {
    
    NSLog(@"Fetching: %@", url.absoluteString);
    
    // factory method:  creates signal for other objects to use
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // will fetch data to parse later
        // TODO:  change this for html!!!
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Handle session here
            if (! error) {
                NSError *htmlError = nil;
                // TODO: use a try/catch block to generate htmlerror
                id htmldoc = [TFHpple hppleWithHTMLData:data];
                if (! htmlError) {
                    [subscriber sendNext:htmldoc];
                } else {
                    [subscriber sendError:htmlError];
                }
            } else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        // will start the request once there is a subscriber
        [dataTask resume];
        
        // include a disposable object to handle cleanup
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        // side effect:  log errors
        NSLog(@"%@",error);
    }];
}



// about separation of concerns:  Ideally, all the details about the Temis Ozone format should be in the OzoneLevel object, but for ozone, there are two stages: 1) extracting the elements from the html page with XPath, and 2) parsing the elements into the model. I'm going to put step 1 here and step 2 in the model. The output of step 1 will be a dictionary correpsonding to the elements needed by the model.

// dom model for temis data:
// html -> body -> 2nd table -> tbody -> tr -> 3rd td -> dl -> dd -> table ->tbody ->
//tr -> td -> <h2> location </h2>
//tr -> 3x td -> (headers as <i>) Date, UV index, ozone
//tr -> 3x td -> (data values) day Month year, .1f, .1f DU

-(RACSignal *)fetchOzoneForecastForLocation:(CLLocationCoordinate2D)coordinate {
    // create the weather data url request string
    NSString *urlString = [NSString stringWithFormat:@"http://www.temis.nl/uvradiation/nrt/uvindex.php?lat=%f&lon=%f",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the RACSignal,
    return [[self fetchHTMLFromURL:url] map:^(TFHpple *doc) {
        
        //build a sequence from the table row nodes in the document
        RACSequence *nodes = [[doc searchWithXPathQuery:@"//dd//tr"] rac_sequence];
        
        //and map the sequence elements
        return [[[[[nodes map:^(TFHppleElement *tableRows){
            
            //by building a sequence from the items in a row
            RACSequence *tableItem = [[tableRows children] rac_sequence];
            
            // and processing each item to get an array of clean strings
            return [[[tableItem map:^(TFHppleElement *child){
                return [[child text]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }] filter:^BOOL(NSString *value) {
                return value.length > 2;
            }] array];
            // at this point, I've got an array of 3 strings containing one row of the table:
            // a date, a UV index value, and an ozone level. I'd like to use these to create ozone level objects
            // to pack into my final array
        }] filter:^BOOL(NSArray *rowArray) {
            return rowArray.count > 0;
        }] map:^(NSArray *rowArray) {
            //NSLog(@"%@", rowArray);
            return [NSDictionary dictionaryWithObjects:rowArray forKeys:@[@"date", @"uvIndex", @"columnOzone"]];
        }] map:^(NSDictionary *rowDict) {
            //NSLog(@"dictionary looks like: %@", rowDict);
            NSError *ozoneError = nil;
            return [[OWOzoneLevel alloc] initWithDictionary:rowDict error:&ozoneError];
        }] array];
        
    }];
}



@end
