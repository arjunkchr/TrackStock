[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/arjunkchr/TrackStock/blob/master/LICENSE)

## TrackStock
My first Swift Application, built using Xcode 7 for iOS 9 that lets user keep track of the stock and notifies the user when the limit is reached. This project uses some of the open source project listed below:
  1.  https://github.com/PhamBaTho/BTNavigationDropdownMenu
  2.  https://github.com/Daniel1of1/CSwiftV

![alt tag](https://github.com/arjunkchr/TrackStock/blob/master/Assets/Demo.gif)

The resulting notification to the user looks like:
![alt tag](https://github.com/arjunkchr/TrackStock/blob/master/Assets/Notification.png)

Feel free to clone/contribute to this project. The only change required to make everything work is get the quandl API key from https://www.quandl.com and using it within the project for urlPath "https://www.quandl.com/api/v3/datasets/WIKI/" + self.ticker + ".json" + "?api_key=*API_KEY*&limit=1" (in ViewController.swift).

Please feel free to provide any pointers or loopholes so I can make the app even better.

##TODO
Make the Background fetch more robust so the fetch is based on timer expiration and not when system wishes to invoke it.
Add a search bar above the navigation title so the user can search through the stocks.
Add all the ticker symbols around the globe.
Make NSURL Session more robust and faster.
Add a Check to determine if wifi or mobile network is available before letting user select a stock.

## License
TrackStock is available under the MIT License. See the [LICENSE](https://github.com/arjunkchr/TrackStock/blob/master/LICENSE) for details.
