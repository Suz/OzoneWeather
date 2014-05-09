#OzoneWeather
Intention:  
project will incorporate style from iOS 7 best practices blog on Wenderlich (sample app: [SimpleWeather](http://www.raywenderlich.com/55384/ios-7-best-practices-part-1)). It will also add in Ozone data from the NL database, using libxml2 and Hpple based on another tutorial [how to parse HTML on iOS](http://www.raywenderlich.com/14172/how-to-parse-html-on-ios).  

The weather feed contains sunrise / sunset data, which will give an indication of the day length. I can combine that with latitude, time, and weather to give a decent estimate of UV conditions. 

##Technologies
The iOS best practices post includes a number of interesting technologies. I'm going to ignore the front end blur filter they use, but I will keep these:

- [cocoapods](http://cocoapods.org) -- package manager and dependency tracker software
    - `vi podfile`  uses the podfile to determine the dependencies to use (see example in the directory)
    - `pod install` obtains dependencies, creates `pods/` to hold the dependencies and creates a `.xcworkspace` file to hold the new project *with* dependencies
- Mantle  -- a project from GitHub for creating data models:  aids conversion JSON <--> NSObject (very handy with a json data feed, as we'll see!)
- [TSMessages](https://github.com/toursprung/TSMessages) -- a ticker-style alert message system. 
- [ReactiveCocoa](https://github.com/Mantle/Mantle) -- allows you to use functional programming constructions in iOS apps
- version control with git:
     - There's always the question of what to add to `.gitignore`. For `cocoapods` see the pros and cons at [guides.cocoapods.org](http://guides.cocoapods.org/using/using-cocoapods.html#should-i-ignore-the-pods-directory-in-source-control).
     - For this project, I want to keep it lightweight, but also keep track of the dependencies. To do this, I'll add the `pods/` directory to `.gitignore`, but keep the `podfile`, `podfile.lock` and other files under version control.
     - used a s[tackoverflow post](http://stackoverflow.com/questions/18939421/what-should-xcode-5-gitignore-file-include) to get an appropriate `.gitignore` file
 

