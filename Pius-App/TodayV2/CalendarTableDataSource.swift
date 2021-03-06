//
//  CalendarTableDataSource.swift
//  Pius-App
//
//  Created by Michael Mosler-Krings on 18.08.19.
//  Copyright © 2019 Felix Krings. All rights reserved.
//

import Foundation
import UIKit

class CalendarTableDataSource: NSObject, UITableViewDataSource, TodayItemDataSourceProtocol {
    
    private var observer: ItemContainerProtocol?
    private var _calendar: Calendar?
    private var hadError: Bool = false

    private var data: [DayItem] {
        get {
            if let calendar = _calendar, calendar.monthItems.count > 0 {
                return calendar.monthItems[0].dayItems
            } else {
                return []
            }
        }
    }

    private func doUpdate(with calendar: Calendar?, online: Bool) {
        hadError = calendar == nil
        if !hadError, let calendar = calendar {
            // Date to filter for. Reduce schedules to the one with the given date.
            let date = Date()
            
            /* ***** DEBUG
            let dateString = "2019-09-12" // change to your date format
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter1.date(from: dateString)!
            */
            
            let dateFormatter = DateFormatter()
            
            // 1. Filter month
            dateFormatter.locale = Locale(identifier: "de_DE")
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            var filterDate = dateFormatter.string(from: date)
            
            var monthItems_ = calendar.monthItems.filter { $0.fullName == filterDate }
            
            // When list not empty filter first month item's day list.
            if monthItems_.count > 0 {
                dateFormatter.setLocalizedDateFormatFromTemplate("EEEEEE dd.MM.")
                filterDate = dateFormatter.string(from: date)
                let index1 = filterDate.index(filterDate.startIndex, offsetBy: 2)
                let index2 = filterDate.index(after: index1)
                filterDate = filterDate.replacingCharacters(in: index1..<index2, with: "")
                monthItems_[0].dayItems = monthItems_[0].dayItems.filter { $0.detailItems[0] == filterDate }
            }
            
            calendar.monthItems = monthItems_
            _calendar = calendar
        }
        
        observer?.didLoadData(self)
    }

    func needsShow() -> Bool {
        return hadError || !isEmpty()
    }
    
    func willTryLoading() -> Bool {
        return true
    }
    
    func isEmpty() -> Bool {
        return data.count == 0
    }
    
    func loadData(_ observer: ItemContainerProtocol) {
        self.observer = observer
        let calendarLoader: CalendarLoader = CalendarLoader()
        calendarLoader.load(doUpdate)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !hadError else { return 1 }
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !hadError else {
            return MessageCell("Der Kalender konnte leider nicht geladen werden.")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "calendarItemCell") as! CalendarTableViewCell
        cell.event = data[indexPath.row].detailItems[1]
        return cell
    }
}
