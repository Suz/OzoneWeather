#OzoneWeather
  
A simple weather app that encorporates UV and ozone data from [TEMIS](http://www.temis.nl). Also calculates sunrise, sunset, solar noon, current and forecast hourly UV index, and time to vitamin D. The time to vitamin D is calculated for a person with European type II skin, with 25% of skin surface exposed -- a t-shirt and pants -- synthesizing roughly 1000 IU of vitamin D. 

**Please note:** The Tropospheric Emission Monitoring Internet Service (TEMIS) ozone service no longer lists terms of service on their website. Please contact them if you wish to incorporate this data stream in a released product.   

###Sources and references:

This app is base on the tutorial: [SimpleWeather](http://www.raywenderlich.com/55384/ios-7-best-practices-part-1). 

The TEMIS data is parsed using `libxml2` and `Hpple`,  based on another tutorial [how to parse HTML on iOS](http://www.raywenderlich.com/14172/how-to-parse-html-on-ios).  

The iOS best practices post includes a number of interesting technologies.
 
- [cocoapods](http://cocoapods.org) 
- [Mantle](https://github.com/Mantle/Mantle)  
- [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) 
- [hpple](https://github.com/topfunky/hpple)
- [TSMessages](https://github.com/toursprung/TSMessages)  

#####Astronomy:
- Roberto Grena, An algorithm for the computation of the solar position, *Solar Energy*, **v.82** (2008), pp 462–470.
- equationOfTime: approximate solution based on [Astronomical Answers](http://aa.quae.nl/en/index.html)
- earth-sun distance:  US Naval Observatory, [approximate solar coordinates](http://aa.usno.navy.mil/faq/docs/SunApprox.php)

and others.

