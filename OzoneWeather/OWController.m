//
//  OWController.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 08/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWController.h"
#import "OWManager.h"
#import "OWCondition.h"
#import "OWOzoneLevel.h"

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
    CGFloat iconSize = 30;
    
    CGRect hiLoFrame = CGRectMake(inset,
                                      headerFrame.size.height - hiLoHeight,
                                      headerFrame.size.width - (2 * inset),
                                      hiLoHeight);
    
    CGRect temperatureFrame = CGRectMake(inset,
                                         headerFrame.size.height - hiLoHeight - temperatureHeight,
                                         headerFrame.size.width - (2 * inset),
                                         temperatureHeight);

    CGRect iconFrame = CGRectMake(inset,
                                  headerFrame.size.height - hiLoHeight - temperatureHeight -iconSize,
                                  iconSize,
                                  iconSize);
    
    CGRect conditionsFrame = iconFrame;
    conditionsFrame.size.width = headerFrame.size.width - (2 * inset) - iconSize + 10;
    conditionsFrame.origin.x = iconFrame.origin.x + iconSize + 10;
    
    UIView *header = [[UIView alloc] initWithFrame:headerFrame];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
    
    //top center
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 30)];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.textColor = [UIColor blackColor];
    cityLabel.text = @"Loading....";
    cityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cityLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:cityLabel];

    //center
    UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:temperatureFrame];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    temperatureLabel.textColor = [UIColor blackColor];
    temperatureLabel.text = @"0°";
    temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120];
    [header addSubview:temperatureLabel];
    
    //bottom left
    UILabel *conditionsLabel = [[UILabel alloc] initWithFrame:conditionsFrame];
    conditionsLabel.backgroundColor = [UIColor clearColor];
    conditionsLabel.textColor = [UIColor blackColor];
    conditionsLabel.text = @"Clear";
    conditionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    [header addSubview:conditionsLabel];
    
    //bottom left
    UILabel *hiLoLabel = [[UILabel alloc] initWithFrame:hiLoFrame];
    hiLoLabel.backgroundColor = [UIColor clearColor];
    hiLoLabel.textColor = [UIColor blackColor];
    hiLoLabel.text = @"0° / 0°";
    hiLoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
    [header addSubview:hiLoLabel];
    
    
    //bottom left
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    [header addSubview:iconView];
    
    [self.view addSubview:self.tableView];
    
    [[RACObserve([OWManager sharedManager], currentCondition)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OWCondition *newCondition){
         temperatureLabel.text = [NSString stringWithFormat:@"%.0f°",newCondition.temperature.floatValue];
         conditionsLabel.text = [newCondition.conditionDescription capitalizedString];
         cityLabel.text = [newCondition.locationName capitalizedString];
         
         iconView.image = [UIImage imageNamed:[newCondition imageName]];
     }];
    
    RAC(hiLoLabel, text) = [[RACSignal combineLatest:@[
                                    RACObserve([OWManager sharedManager],currentCondition.hiTemp),
                                    RACObserve([OWManager sharedManager], currentCondition.loTemp)]
                                    reduce:^(NSNumber *hi, NSNumber *low){
                                            return [NSString stringWithFormat:@"%.0f° / %.0f°", hi.floatValue, low.floatValue];
                                    }]
                            deliverOn:RACScheduler.mainThreadScheduler];
    
    [[RACObserve([OWManager sharedManager], hourlyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast){
         [self.tableView reloadData];
     }];
    
    [[RACObserve([OWManager sharedManager], dailyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast){
         [self.tableView reloadData];
     }];
    
    [[RACObserve([OWManager sharedManager], ozoneForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast){
         iconView.backgroundColor = [[newForecast firstObject] dangerLevel];
         NSLog(@"The clear sky uvIndex is: %@", [[newForecast firstObject] uvIndex]);
     }];
    
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
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"Hourly Forecast"];
        } else {
            OWCondition *weather = [OWManager sharedManager].hourlyForecast[indexPath.row - 1];
            [self configureHourlyCell:cell withWeather: weather];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"Daily Forecast"];
        } else {
            OWCondition *weather = [OWManager sharedManager].dailyForecast[indexPath.row - 1];
            [self configureDailyCell:cell withWeather: weather];
        }
    }
    
    return cell;
}

-(void)configureHeaderCell:(UITableViewCell *)cell title:(NSString *)title {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = @"";
    cell.imageView.image = nil;
}

-(void)configureHourlyCell:(UITableViewCell *)cell withWeather:(OWCondition *)weather {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.hourlyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f°", weather.temperature.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)configureDailyCell:(UITableViewCell *)cell withWeather:(OWCondition *)weather {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.dailyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° / %.0f°", weather.hiTemp.floatValue, weather.loTemp.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

# pragma mark -- UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;  // TODO:  determine based on size of screen.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
