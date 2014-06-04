//
//  OWController.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 08/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWController.h"
#import "OWManager.h"

#import "OWViewData.h"
#import "RACEXTScope.h"

@interface OWController ()

@property (nonatomic,strong) UIImageView *backgroundImageView;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,assign) CGFloat screenHeight;

@property (nonatomic,strong) NSDateFormatter *hourlyFormatter;
@property (nonatomic,strong) NSDateFormatter *dailyFormatter;

@end

@implementation OWController

-(id)init {
    if (self = [super init]) {
        _hourlyFormatter = [[NSDateFormatter alloc] init];
        _hourlyFormatter.dateFormat = @"h a";
        
        _dailyFormatter = [[NSDateFormatter alloc] init];
        _dailyFormatter.dateFormat = @"EEEE";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    // bottom layer:  background image (default SF)
    UIImage *background = [UIImage imageNamed:@"floatyclouds"];
    self.backgroundImageView = [[UIImageView alloc] initWithImage:background];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    
    
    // top layer: tableView
    //          -- main tableview setup
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    self.tableView.pagingEnabled = YES;
    
    //          -- tableview header setup: frames for weather items
    CGRect headerFrame = [UIScreen mainScreen].bounds;
    
    CGFloat inset = 20;
    
    CGFloat temperatureHeight = 110;
    CGFloat hiLoHeight = 40;
    CGFloat iconFrameSize = 40;
    
    CGRect hiLoFrame = CGRectMake(inset,
                                      headerFrame.size.height - hiLoHeight,
                                      headerFrame.size.width - (2 * inset),
                                      hiLoHeight);
    
    CGRect temperatureFrame = CGRectMake(inset,
                                         headerFrame.size.height - hiLoHeight - temperatureHeight,
                                         headerFrame.size.width - (2 * inset),
                                         temperatureHeight);

    CGRect iconFrame = CGRectMake(inset,
                                  headerFrame.size.height - hiLoHeight - temperatureHeight -iconFrameSize,
                                  iconFrameSize,
                                  iconFrameSize);
    
    CGRect conditionsFrame = iconFrame;
    conditionsFrame.size.width = headerFrame.size.width - (2 * inset) - iconFrameSize + 10;
    conditionsFrame.origin.x = iconFrame.origin.x + iconFrameSize + 10;
    
    UIView *header = [[UIView alloc] initWithFrame:headerFrame];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
    
    //top center
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 30)];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.textColor = [UIColor whiteColor];
    cityLabel.text = @"Loading....";
    cityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cityLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:cityLabel];

    //center
    UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:temperatureFrame];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    temperatureLabel.textColor = [UIColor whiteColor];
    temperatureLabel.text = @"0°";
    temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120];
    [header addSubview:temperatureLabel];
    
    //bottom left
    UILabel *conditionsLabel = [[UILabel alloc] initWithFrame:conditionsFrame];
    conditionsLabel.backgroundColor = [UIColor clearColor];
    conditionsLabel.textColor = [UIColor whiteColor];
    conditionsLabel.text = @"Clear";
    conditionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    [header addSubview:conditionsLabel];
    
    //bottom left
    UILabel *hiLoLabel = [[UILabel alloc] initWithFrame:hiLoFrame];
    hiLoLabel.backgroundColor = [UIColor clearColor];
    hiLoLabel.textColor = [UIColor whiteColor];
    hiLoLabel.text = @"0° / 0°";
    hiLoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    [header addSubview:hiLoLabel];
    
    
    //bottom left
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode = UIViewContentModeCenter;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.layer.cornerRadius = 5.0;
    iconView.layer.masksToBounds = YES;
    [header addSubview:iconView];
    
    [self.view addSubview:self.tableView];
    
    
    // Respond to data updates:
    //          -- current weather
    [[RACObserve([OWManager sharedManager], currentWeather)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OWViewData *currentWeather){
         temperatureLabel.text = [NSString stringWithFormat:@"%.0f°",currentWeather.temperature.floatValue];
         conditionsLabel.text = [currentWeather.conditionDescription capitalizedString];
         cityLabel.text = [currentWeather.locationName capitalizedString];
         
         hiLoLabel.text = currentWeather.vitaminDTime;
         iconView.image = [UIImage imageNamed:[currentWeather weatherImageName]];
         iconView.backgroundColor = [currentWeather uvDangerLevel];
     }];
    
  /*  RAC(hiLoLabel, text) = [[RACSignal combineLatest:@[
                                    RACObserve([OWManager sharedManager], currentWeather.hiTemp),
                                    RACObserve([OWManager sharedManager], currentWeather.loTemp)]
                                    reduce:^(NSNumber *hi, NSNumber *low){
                                            return [NSString stringWithFormat:@"%.0f° / %.0f°", hi.floatValue, low.floatValue];
                                    }]
                            deliverOn:RACScheduler.mainThreadScheduler];
   */
    
    
    //          -- hourly forecasts
    [[RACObserve([OWManager sharedManager], hourlyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast){
        // NSLog(@"new hourly forecast: %@", newForecast);
         [self.tableView reloadData];
     }];
    
    //          -- daily forecasts
    [[RACObserve([OWManager sharedManager], dailyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast){
         //NSLog(@"new daily forecast: %@", newForecast);
         [self.tableView reloadData];
     }];
    
    // Start up the data gathering process:
    [[OWManager sharedManager] findCurrentLocation];
   
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    
    self.backgroundImageView.frame = bounds;
    self.tableView.frame = bounds;
}

# pragma mark -- UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        return MIN([[OWManager sharedManager].hourlyForecast count], 6) + 1;
    }
    
    return MIN([[OWManager sharedManager].dailyForecast count], 6) + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"Hourly Forecast"];
        } else {
            OWViewData *weather = [OWManager sharedManager].hourlyForecast[indexPath.row - 1];
            [self configureHourlyCell:cell withWeather: weather];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"Daily Forecast"];
        } else {
            OWViewData *weather = [OWManager sharedManager].dailyForecast[indexPath.row - 1];
            [self configureDailyCell:cell withWeather: weather];
        }
    }
    
    return cell;
}

-(void)configureHeaderCell:(UITableViewCell *)cell title:(NSString *)title {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = title;
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    cell.detailTextLabel.text = @"°F | UV Index | vit. D";
    cell.imageView.image = nil;
}

-(void)configureTableCell:(UITableViewCell *)cell{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    cell.imageView.contentMode = UIViewContentModeCenter;
    cell.imageView.layer.cornerRadius = 5.0;
    cell.imageView.layer.masksToBounds = YES;
}

-(void)configureHourlyCell:(UITableViewCell *)cell withWeather:(OWViewData *)weather {
    [self configureTableCell:cell];
    cell.textLabel.text = [self.hourlyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° | %@ | %@", weather.temperature.doubleValue, weather.uvIndex, weather.vitaminDTime];
    cell.imageView.image = [UIImage imageNamed:[weather weatherImageName]];
    cell.imageView.backgroundColor = [weather uvDangerLevel];
}

-(void)configureDailyCell:(UITableViewCell *)cell withWeather:(OWViewData *)weather {
    [self configureTableCell:cell];
    cell.textLabel.text = [self.dailyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° | %@ | %@", weather.hiTemp.doubleValue, weather.maxUVIndex, weather.vitaminDTime];
    cell.imageView.image = [UIImage imageNamed:[weather weatherImageName]];
    cell.imageView.backgroundColor = [weather maxUVDangerLevel];
}

# pragma mark -- UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.screenHeight / [self tableView:tableView numberOfRowsInSection:indexPath.section];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
