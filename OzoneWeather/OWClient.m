//
//  OWClient.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWClient.h"
#import "OWCondition.h"
#import "OWDailyForecast.h"

@interface OWClient ()

@property (nonatomic,strong) NSURLSession *session;

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

//TODO:  there's a lot of repetition in the next three methods. The things that change are the url strings, the model to return, and whether or not the data is a single dictionary (current conditions) or an array (hourly or daily forecasts). These could be abstracted out of a single fetch method.

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
        return [[list map:^(NSDictionary *json){
            //from json objects to an array OWConditions objects using the adapter. whew.
            return [MTLJSONAdapter modelOfClass:[OWCondition class] fromJSONDictionary:json error:nil];
        }] array];
        
    }];
}

-(RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    // create the weather data url request string
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the RACSignal,
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        
        //build a sequence from the list of raw json
        RACSequence *list = [json[@"list"] rac_sequence];
        
        //and map the sequence elements
        return [[list map:^(NSDictionary *json){
            //from json objects to an array OWDailyForecast objects using the Mantle whew.
            return [MTLJSONAdapter modelOfClass:[OWDailyForecast class] fromJSONDictionary:json error:nil];
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

-(RACSignal *)fetchOzoneForecastForLocation:(CLLocationCoordinate2D)coordinate {
    // create the weather data url request string
    NSString *urlString = [NSString stringWithFormat:@"http://www.temis.nl/uvradiation/nrt/uvindex.php?lat=%f&lon=%f",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create the RACSignal,  TODO: fix me for html, not json!
    return [[self fetchHTMLFromURL:url] map:^(NSDictionary *json) {
        
        //build a sequence from the list of raw json
        RACSequence *list = [json[@"list"] rac_sequence];
        
        //and map the sequence elements
        return [[list map:^(NSDictionary *json){
            //from json objects to an array OWDailyForecast objects using the Mantle whew.
            return [MTLJSONAdapter modelOfClass:[OWDailyForecast class] fromJSONDictionary:json error:nil];
        }] array];
        
    }];
}


@end
