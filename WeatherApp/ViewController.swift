/*
 RMIT University Vietnam
 Course: COSC2659 iOS Development
 Semester: 2018B
 Assessment: Project
 Author: Nguyen Bao Minh, Hoang Duc Hung, Nguyen Phi Long, Nguyen Huynh Viet Dung
 ID: s3574957, s3426106, s3574967, s3532924
 Created date: 17/09/2018
 Acknowledgment: We used APIs of DarkSky and Openweathermap
 https://darksky.net/forecast/40.7127,-74.0059/us12/en
 https://openweathermap.org/
 */
//
//  ViewController.swift


import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView
import CoreLocation



class ViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    //Outlet
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var uvIndexLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    

    
    //API secret keys
    let darkSkyApiKey = "c56c4ffc63b212daf14f276378b18b97"
    let openWeatherApiKey = "b9d7853fa6eb9dad94d386b7999d4444"
    
    var activityIndicator: NVActivityIndicatorView!
    let locationManager = CLLocationManager()
    
    var searchString = ""
    var modifiedString = ""
    
    var lon = ""
    var lat = ""
    
    var HourlyDataList = [String]()
    var HourlyTempList = [String]()
    var DailyDataList = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        let indicatorSize: CGFloat = 70
        let indicatorFrame = CGRect(x: (view.frame.width-indicatorSize)/2, y: (view.frame.height-indicatorSize)/2, width: indicatorSize, height: indicatorSize)
        
        activityIndicator = NVActivityIndicatorView(frame: indicatorFrame, type: .lineScale, color: UIColor.white, padding: 20.0)
        activityIndicator.backgroundColor = UIColor.black
        
        view.addSubview(activityIndicator)
        
        locationManager.requestWhenInUseAuthorization()
        
        activityIndicator.startAnimating()
        
        
        
    }
    
/*
     In the block of code below we will fetch data from both APIs.
     The reason we have to use 2 APIs is because DarkSky's API provide alot of useful data but it use latitude and longtitude to search locations instead of city name.
     On the other hand, the Openweathermap's API does support search by city name and it returns the city's latitude and longitude.
     Hence, we use the latitude and longitude from Openweathermap's API to retrieve data from DarkSky's API
     
     After access to those APIs, we decided to use needed data for current weather, daily weather and hourly weather in this block of code
*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]

        
        Alamofire.request("http://api.openweathermap.org/data/2.5/weather?q=\(modifiedString)&appid=\(openWeatherApiKey)&units=metric").responseJSON{
            response in
            if let responseLocationStr = response.result.value{
                
                //getting message from openweathermap's API
                let jsonLocationReponse = JSON(responseLocationStr)
                let jsonMessage = jsonLocationReponse["message"]
                
                if jsonMessage == "city not found"{ //gives alert if user enter wrong city name
                    self.createAlert(title: "City not found", message: "City name is not found")
                }
                else{
                    self.lat = jsonLocationReponse["coord"]["lat"].stringValue
                    self.lon = jsonLocationReponse["coord"]["lon"].stringValue
                    
                    Alamofire.request("https://api.darksky.net/forecast/\(self.darkSkyApiKey)/\(self.lat),\(self.lon)").responseJSON{
                        response in
                        self.activityIndicator.stopAnimating()
                        if let responseStr = response.result.value{
                            let jsonResponse = JSON(responseStr)
                            self.locationLabel.text = self.searchString
                            let jsonCurrentData = jsonResponse["currently"]
                            self.conditionLabel.text = jsonCurrentData["summary"].stringValue
                            
                            self.temperatureLabel.text = ("\(self.cDegreeConverter(fDegreeInput: jsonCurrentData["temperature"].stringValue))" + "°")
                            
                            self.humidityLabel.text = "Humidity: " + "\(Int((jsonCurrentData["humidity"].doubleValue)*100))"  + "%"
                            
                            self.uvIndexLabel.text = "UV Index: " + jsonCurrentData["uvIndex"].stringValue
                            
                            
                            
                            //HOURLY DATA
                            let jsonHourlyData = jsonResponse["hourly"]
                            
                            let closestTime = jsonHourlyData["data"][0]["time"].stringValue
                            
                            //taking first 12 character from date time for comparing
                            let modifiedClosestTime = self.dateTimeConverter(dateTimeString: closestTime).prefix(12)
                            
                            
                            var i = 0
                            
                            while true {
                                let jsonHourlyTime = jsonHourlyData["data"][i]["time"].stringValue
                                
                                //taking first 12 character from date time for comparing
                                let modifiedHourlyTime = self.dateTimeConverter(dateTimeString: jsonHourlyTime).prefix(12)
                                
                                //break the loop if time goes to next day
                                if modifiedClosestTime != modifiedHourlyTime {
                                    break
                                }
                                
                                //getting hourly data then send to UI
                                let convertedHourlyTime = self.dateTimeConverter(dateTimeString: jsonHourlyTime)
                                let hourlyTemperature = self.cDegreeConverter(fDegreeInput: jsonHourlyData["data"][i]["temperature"].stringValue)
                                self.HourlyDataList.append(String(convertedHourlyTime.suffix(8)))
                                self.HourlyTempList.append(String(hourlyTemperature) + "°C")
                                self.insertNewCollection()
                                print(self.HourlyDataList)
                                //////
                                
                                //increasement to get data from next element of the array
                                i = i + 1
                                
                                
                            } //end while
                            
                            //DAILY DATA
                            let jsonDailyData = jsonResponse["daily"]
                            
                            for i in 0...6{
                                let dailyDateTime = jsonDailyData["data"][i]["time"].stringValue
                                let convertedDailyDateTime = self.dateTimeConverter(dateTimeString: dailyDateTime).prefix(6)
                                
                                let dailyMaxTemperature = self.cDegreeConverter(fDegreeInput: jsonDailyData["data"][i]["temperatureMax"].stringValue)
                                let dailyMinTemperature = self.cDegreeConverter(fDegreeInput: jsonDailyData["data"][i]["temperatureMin"].stringValue)
                                
                                self.DailyDataList.append(String(convertedDailyDateTime) + "                                      "  + String(dailyMaxTemperature) + "    " + String(dailyMinTemperature))
                                self.tableView.reloadData()
                                
                            }//end for loop
                            
                        } //end of if let responseStr = response.result.value
                        
                    } //end almofire dark sky
                    self.locationManager.stopUpdatingLocation()
                } //end of else
            } //end of if let responseLocationStr = response.result.value
        }  //end almofire openweathermap
    } //end function locationManager
    
    
    
    //Search bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchString = searchBar.text!
        HourlyTempList.removeAll()
        HourlyDataList.removeAll()
        DailyDataList.removeAll()
        tableView.reloadData()
        collectionView.reloadData()
        modifiedString = searchString.replacingOccurrences(of: " ", with: "%20")
        

        
        if(CLLocationManager.locationServicesEnabled()){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
        }
    }
    
    //Alert for reuse
    func createAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Try Again!", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //CREATE TABLE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(DailyDataList.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        cell.textLabel?.text = DailyDataList[indexPath.row]
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        return(cell)
    }
    
    //CREATE COLLECTION
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return(HourlyDataList.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CollectionViewCell
        
        cell.hourlyLabel.text = HourlyDataList[indexPath.item]
        cell.hourlyTempLabel.text = HourlyTempList[indexPath.item]
        return cell
        
    }
    
    
    func insertNewCollection() {
        let indexPath = IndexPath(item: HourlyDataList.count - 1, section: 0)
        
        collectionView.insertItems(at: [indexPath])
    }
    
    //Convert UNIX number time to user friendly time
    func dateTimeConverter(dateTimeString: String) -> String{
        let tempDate = dateTimeString
        let convertedDate = Date(timeIntervalSince1970: TimeInterval(tempDate)!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let currentDate = dateFormatter.string(from: convertedDate)
        return currentDate
    }
    
    //Convert Fahrenheit to Celsius
    func cDegreeConverter(fDegreeInput: String) -> Int{
        let convertedCDegree = Int(round((Double(fDegreeInput)!-32)*(5/9)))
        return convertedCDegree
    }

}

