//
//  OWController.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 08/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWController.h"
#import "OWManager.h"

@interface OWController ()

@property (nonatomic,strong) UIImageView *backgroundImageView;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,assign) CGFloat screenHeight;

@end

@implementation OWController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
                                  headerFrame.size.height - hiLoHeight - temperatureHeight,
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
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // 3
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // TODO: Setup the cell
    
    return cell;
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
