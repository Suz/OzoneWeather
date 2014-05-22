//
//  OWViewManager.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 16/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>

#import "OWViewData.h"

@interface OWViewManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) OWViewData *currentData;
@property (nonatomic, strong, readonly) NSArray *hourlyData;
@property (nonatomic, strong, readonly) NSArray *dailyData;

-(RACSignal *)currentWeather;

@end
