#OzoneWeather
Intention:  
project will incorporate style from iOS 7 best practices blog on Wenderlich (sample app: [SimpleWeather](http://www.raywenderlich.com/55384/ios-7-best-practices-part-1)). It will also add in Ozone data from the NL database, using libxml2 and Hpple based on another tutorial [how to parse HTML on iOS](http://www.raywenderlich.com/14172/how-to-parse-html-on-ios).  

The weather feed contains sunrise / sunset data, which will give an indication of the day length. I can combine that with latitude, time, and weather to give a decent estimate of UV conditions. 

##Technologies
The iOS best practices post includes a number of interesting technologies. I'm going to ignore the front end blur filter they use, but I will keep these:

- [cocoapods](http://cocoapods.org) -- package manager and dependency tracker software
    - `vi podfile`  cocoapods searches for a file named 'podfile'. Include the dependencies to be included with the project there (see example in the directory)
    - `pod install` obtains the dependencies, creates `pods/` to hold the dependencies and creates a `.xcworkspace` file to hold the new project *with* dependencies
    - `pod update` will update a dependency to the latest version. I acutally had to do this in this project because the TSMessage project had suffered from a problem at GitHub and they needed to put in a bug fix. It worked like a charm!
- Mantle  -- a project from GitHub for creating data models:  aids conversions between JSON <--> NSObject (very handy with a json data feed, as we'll see!). I only wish there were more useful tools for directly converting a dictionary into an object. I didn't come up with a good solution, but at least it works, and it's pretty easy to see how it could be improved. 
- [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) -- allows you to use functional programming constructions in iOS apps. Ever run into a spaghetti of callbacks with KVO? Functional Reactive programming may not be the ultimate solution, but it certainly provides a different paradigm that applies to many common situations. Wow. If you haven't used it you, you gotta try this stuff.
- [hpple](https://github.com/topfunky/hpple) I needed an HTML parser for iOS. There are a lot of choices, but this one had a decent tutorial at Ray Wenderlich.com, and seemed easy to use (and it was). The parsing problem is pretty small as I only want to do a single page that hasn't changed in years. [Regex would have worked](http://blog.codinghorror.com/parsing-html-the-cthulhu-way/), but I wanted to learn how to do it better. 
- [TSMessages](https://github.com/toursprung/TSMessages) -- a ticker-style alert message system. 
- [git](http://www.git-scm.com) for version control -- the technology driving collaborative development on github. Can't say I've mastered the learning curve yet. This is one of those situations where a video explanation really helps. Jessica Kerr (@jessitron) does a great one, [git happens -- with sticky notes](http://vimeo.com/46010208)! (this particular presentation is for coders coming from a background in subversion, but I've also seen Jessica do a great intro for novices who haven't heard of version control at all. The'll be under the name 'git happens' as well).
     - As with any newly hatched project, there's the question of what to add to `.gitignore`. For a project using `cocoapods`, see the pros and cons at [guides.cocoapods.org](http://guides.cocoapods.org/using/using-cocoapods.html#should-i-ignore-the-pods-directory-in-source-control).
     - For this project, I want to keep it lightweight, but also keep track of the dependencies. To do this, I'll add the `pods/` directory to `.gitignore`, but keep the `podfile`, `podfile.lock` and other files under version control.
     - used a [stackoverflow post](http://stackoverflow.com/questions/18939421/what-should-xcode-5-gitignore-file-include) to get an appropriate `.gitignore` file
     
     
###Temis
The ozone data I'm using is basically scraping a website. It is old website, and lacks a friendly api. Raw science. To get the column ozone for a location, I need to query the website with a url string of the type `http://www.temis.nl/uvradiation/nrt/uvindex.php?lon=5.18&lat=52.1`, where the `lon` and `lat` values are provided by my code. The response is only available as .html, so I need to get this response and parse it to extract the desired column ozone values. I'll use hpple to parse the html response and it's xpath query system to walk the DOM and extract values from the relevant table. 

The entire page is formated as a series of nested tables. The page header is one table; a second table holds the body of the page with one column holding the frame to the left, a blank column, and a column holding the data table I'm interested in.    
html -> body -> 2nd table -> tbody -> tr -> 3rd td -> dl -> dd -> table ->tbody ->
tr -> td -> <h2> location </h2>
tr -> 3x td -> (headers as <i>) Date, UV index, ozone
tr -> 3x td -> (data values) day Month year, .1f, .1f DU

There are a lot of XML parsers and JSON parsers available. In a perfect world, .html files could be parsed as xml, but it doesn't work out that way. Many normal tags in .html are not xml compliant, so most xml parsers break down right away, inclduing the NSXMLParser included in iOS. Parsing .html is not an uncommon problem, so there are a number of librarires on GitHub that people have used. I used Hpple, which worked well, and I was able to combine with with reactive cocoa to create a pipeline straight from .html to my model objects.

There are still a few wrinkles that could use ironing. When dealing with locatioins time zones and solar data, times and dates become difficult to handle. The native date-handling in iOS doesn't make it easier, either. The UV Index published by TEMIS is for solar noon at the lat,lon location. Presumable, the column ozone is a prediction for the same time, although the website isn't specific. There is no accurate way to use only iOS internals to capture this date correctly. I also need time of solar noon at the location of interest, which creates a some problems, particularly when daylight savings time is taken into account in different jurisdictions, globally. Time is a mess.  

###Lessons
**DateFormatter:**
'HH' parses 24hr time, hh parses am, pm time. 'hh' won't parse 17:20.
'YYYY' doesn't mean 2014. For normal years you need 'yyyy'. 
The full spec for iOS 7 is at [unicode.org](http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Parsing_Dates_Times)
**ReactiveCocoa:**
NSLog is useful for getting info on intermediate stages.
There are some mysteries about what `filter:` and `ignore:` do that I should get a grip on.
There is a lot of potential in this library, and many functions to explore. `map:` is your friend. Use it flexibly. 

Useful discussions in the issues and on SO. One thing is that this library is changing rapidly -- 2.0 was recently released and 3.0 is being crafted. The terminology is shifting, even for core ideas. 

- prefer RACSignal over RACSequence. 
- Prefer 1-way binding with RAC over 2-way binding. (see discussion of issue proposign to drop RACChannel)
- avoid `subscribeNext:`, `doError:`, and `doNext:`. These break the functional paradigm. (http://stackoverflow.com/questions/17281424/how-would-you-write-fetching-a-collection-the-reactive-cocoa-way) Note: `RACAble` was replaced with `RACObserve` in 2.0. 

I'm finding it somewhat diffuclt to chain my signals together in the correct way, probably because I have some processing to do with different parts of the ozone signal. 

Here's a helpful bit of code from [techsfo.com/blog/2013/08](http://www.techsfo.com/blog/2013/08/managing-nested-asynchronous-callbacks-in-objective-c-using-reactive-cocoa/) for managing nested asynchronous network calls in which one call depends on the results of the previous. Note: this is from August, so before RAC 2.0. I believe `weakself` is now created with the decorator pattern `@weakify` and destroyed with the decorator `@strongify`.

    __weak id weakSelf = self;
    [[[[[self signalGetNetworkStep1] flattenMap:^RACStream*(id *x) {
       // perform your custom business logic
       return [weakSelf signalGetNetworkStep2:x];
    }] flattenMap:^RACStream*(id *y) {
       // perform additional business logic
       return [weakSelf signalGetNetworkStep3:y];
    }] flattenMap:^RACStream*(id *z) {
       // more business logic
       return [weakSelf signalGetNetworkStep4:z];
    }] subscribeNext:^(id*w) {
       // last business logic
    }];

More recently, there this a handy bit of pseudo-code embedded in an [SO answer](http://stackoverflow.com/questions/22100683/how-to-combine-afnetworking-2-0-with-reactive-cocoa-to-chain-a-queue-of-requests) concerning chaining a series of requests:

    [[self 
        executeLoginRequest] 
        flattenMap:^(id transactionId) {
            return [[[self 
                executeUpdateRequest:data withTransactionId:transactionId] 
                then:^{
                    return [self executeUploadRequest:jpeg withTransactionId:transactionId];
                }] 
                then:^{
                    return [self endRequests:transactionId];
                }];
        }]

The code is very similar in the use of flattenMap:, but the second version (chaining) uses `then:` instead of additional `flattenMap:` and `subscribeNext:`. Since `subscribeNext:` is to be avoided, let's look into `then:`. Ah, no. The header files are your friend.

Regarding `then:`

    /// Ignores all `next`s from the receiver, waits for the receiver to complete,
    /// then subscribes to a new signal.
    ///
    /// block - A block which will create or obtain a new signal to subscribe to,
    ///         executed only after the receiver completes. This block must not be
    ///         nil, and it must not return a nil signal.
    ///
    /// Returns a signal which will pass through the events of the signal created in
    /// `block`. If the receiver errors out, the returned signal will error as well.
    - (RACSignal *)then:(RACSignal * (^)(void))block;

vs `subscribeNext:`

In the end, I used `subscribeNext` because I got that to work. Elegance is yet to be learned. I'm fomenting a question for SO on when to move in / out of the functional paradigm. I can envision this app as almost entirely functional, but I am currently unable to get `RAC` to handle the signals quite the way I want. More learning to do. 

###TODO
- I think there's a memory leak somewhere. It's fairly small, but these things add up. I need to get up to speed with instruments and identifying leaks again. Things have changed quite a bit since XCode 4. 
- use different sky images for the background to reflect the weather prediction.
(might be a bad idea). ()Potentially ugly and disorienting for the user.)
- The original background of the table view had a blur filter attached. This was accomplished with a library, but I think similar is possible with CALayer. Might be good to explore a CALayer filter on the table-view cells or the underlying scrollview. The filter would respond to scrollview position.  
- UV information is only currently encoded as uvIndex ranges giving a color on the icon background. That's a start, but I'd like to do some calculation and determine two kinds of risk: 
     1. oveall intensity -- risk of acute sunburn, and 
     2. relatively high ratios of UVA at high intensity -- risk of deep damage that is harder for the body to repair. 
     
     To do this, I need to work more at combining the weather signals, possibly changing the model significantly. Thank goodness for git branches!
- (I'd also like to build a mathematical model of the flow of vitaminD, and timing of different kinds of damage and repair in the skin), but that's a pretty significant academic project. or maybe it isn't. Should be a series of competing rate equations, some quite long (vitamin D storage)
   
### Unit Testing
One of the big holes in all this is that there are zero tests. That just isn't OK. The first step is to set up logic tests for my astronomy code. That should be straight forward. I set up XCTest following the directions from WWDC lcture, and created some tests. The first difficutly was that my test class wouldn't let me call any private methods in the class I'm testing. I don't want to move those function definitions into the public interface, and luckily there is another way:  create a category in your test class ([stackoverlfow](http://stackoverflow.com/a/1099281/962009) to the rescue again!). 

    // category used to test private methods
    @interface OWSolarWrapper (Test)
    
    // private functions from OWSolarWrapper.m
    // date functions
    -(NSNumber *) julianDateFor:(NSDate *)date;
    -(NSNumber *) julianCenturyForJulianDate:(NSNumber *)julianDate;
    -(NSNumber *) julianDateRelative2003For:(NSDate *)date;
    
    // basic astronomy calcs
    -(NSNumber *) equationOfTimeFor:(NSDate *)date;
    -(NSDictionary *) solarParametersForDate:(NSDate *)date;
    
    @end

