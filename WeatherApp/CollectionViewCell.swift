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
//  CollectionViewCell.swift


import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var hourlyLabel: UILabel!
    
    @IBOutlet weak var hourlyTempLabel: UILabel!
}
