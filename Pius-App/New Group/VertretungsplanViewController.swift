//
//  VertretungsplanViewController.swift
//  Pius-App
//
//  Created by Michael on 11.03.18.
//  Copyright © 2018 Felix Krings. All rights reserved.
//

import UIKit

class VertretungsplanViewController: UITableViewController, ExpandableHeaderViewDelegate {

    /*
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tickerTextScrollView: UIScrollView!
    @IBOutlet weak var tickerTextPageControl: UIPageControl!
    
    @IBOutlet weak var tableView: UITableView!
     
    @IBOutlet weak var currentDateLabel: UILabel!
    @IBOutlet weak var tickerText: UITextView!
    @IBOutlet weak var additionalText: UITextView!
    
    @IBOutlet weak var offlineLabel: UILabel!
    @IBOutlet weak var offlineFooterView: UIView!
    */
    
    private var vertretungsplan: Vertretungsplan?;
    // private var data: [VertretungsplanForDate] = [];
    private var selected: IndexPath?;
    private var currentHeader: ExpandableHeaderView?;
    
    private var tickerTextScrollViewWidth: Int?;

    private var data: [VertretungsplanForDate] {
        get {
            if let vertretungsplan_ = vertretungsplan {
                return vertretungsplan_.vertretungsplaene;
            }
            return [];
        }
        
        set(newValue) {
            if (vertretungsplan != nil) {
                vertretungsplan!.vertretungsplaene = newValue;
            }
        }
    }

    func doUpdate(with vertretungsplan: Vertretungsplan?, online: Bool) {
        if (vertretungsplan == nil) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Vertretungsplan", message: "Die Daten konnten leider nicht geladen werden.", preferredStyle: UIAlertController.Style.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                    (action: UIAlertAction!) in self.navigationController?.popViewController(animated: true);
                }));
                self.present(alert, animated: true, completion: nil);

                /*
                if (self.offlineLabel != nil && self.offlineFooterView != nil) {
                    self.offlineLabel.isHidden = online;
                    self.offlineFooterView.isHidden = online;
                }
                */
            }
        } else {
            // self.data = vertretungsplan!.vertretungsplaene;
            self.vertretungsplan = vertretungsplan;

            DispatchQueue.main.async {
                self.tableView.reloadData();
            }

            /*
            DispatchQueue.main.async {
                self.currentDateLabel.text = vertretungsplan!.lastUpdate;
                self.tickerText.text = StringHelper.replaceHtmlEntities(input: vertretungsplan!.tickerText);
                
                if (vertretungsplan!.hasAdditionalText()) {
                    self.additionalText.text = StringHelper.replaceHtmlEntities(input: vertretungsplan!.additionalText);
                    self.tickerTextScrollView.isScrollEnabled = true;
                    self.tickerTextPageControl.numberOfPages = 2;
                } else {
                    self.tickerTextScrollView.isScrollEnabled = false;
                    self.tickerTextPageControl.numberOfPages = 1;
                }
                
                self.tableView.reloadData();
                self.activityIndicator.stopAnimating();

                self.offlineLabel.isHidden = online;
                self.offlineFooterView.isHidden = online;
            }
            */
        }
    }
    
    private func getVertretungsplanFromWeb() {
        let vertretungsplanLoader = VertretungsplanLoader(forGrade: nil);
        
        // Clear all data.
        currentHeader = nil;
        selected = nil;
        
        vertretungsplanLoader.load(self.doUpdate);        
    }

    @objc func refreshScrollView(_ sender: UIRefreshControl) {
        getVertretungsplanFromWeb();
        sender.endRefreshing()
    }

    // After sub-views have been layouted content size of ticket text
    // scroll view can be set. As we do not add UIText programmatically
    // scroll view does not know about the correct size from story
    // board.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        // tickerTextScrollView.contentSize = CGSize(width: 2 * tickerTextScrollViewWidth!, height: 70);
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        refreshControl!.addTarget(self, action: #selector(refreshScrollView(_:)), for: UIControl.Event.valueChanged);
        getVertretungsplanFromWeb();
    }

    /*
    // Sets current page of page control when ticker text is
    // scrolled horizontally.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == tickerTextScrollView) {
            let currentPage = round(scrollView.contentOffset.x / CGFloat(tickerTextScrollViewWidth!));
            tickerTextPageControl.currentPage = Int(currentPage);
        }
    }
    */

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selected = indexPath;
        return indexPath;
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vertretungsplanDetailViewController = segue.destination as? VertretungsplanDetailViewController, let selected = self.selected {
            vertretungsplanDetailViewController.gradeItem = data[selected.section].gradeItems[selected.row];
            vertretungsplanDetailViewController.date = data[selected.section].date;
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count + 2;
    }

    // Returns number of rows in section. The first two sections are fix and have one row only
    // for all following sections the number of grade items defines the number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return (section < 2) ? 1 : data[section - 2].gradeItems.count;
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            return 110;
        }

        if (indexPath.section == 1) {
            return UITableView.automaticDimension;
        } else {
            return (data[indexPath.section - 2].expanded) ? 44 : 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return 0;
        }

        return (section < 2) ? UITableView.automaticDimension : 44;
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section < 2) ? 0 : 2;
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section < 2) {
            return UITableViewHeaderFooterView();
        } else {
            let header = ExpandableHeaderView();
            header.customInit(title: data[section - 2].date, userInteractionEnabled: data[section - 2].gradeItems.count > 0, section: section, delegate: self);
            return header;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell;
        
        switch(indexPath.section) {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "metaDataCell")!;
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "lastUpdateCell")!;
            cell.textLabel?.text = vertretungsplan?.lastUpdate;
            cell.detailTextLabel?.text = "Letzte Aktualisierung";
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "labelCell")!;
            cell.textLabel?.text = data[indexPath.section - 2].gradeItems[indexPath.row].grade;
        }
        return cell;
    }
    
    // Toggles section headers. If a new header is expanded the previous one when different
    // from the current one is collapsed.
    func toggleSection(header: ExpandableHeaderView, section: Int) {
        // If another than the current section is selected hide the current
        // section.
        if (currentHeader != nil && currentHeader != header) {
            let currentSection = currentHeader!.section!;
            data[currentSection - 2].expanded = false;
            
            tableView.beginUpdates();
            for i in 0 ..< data[currentSection - 2].gradeItems.count {
                tableView.reloadRows(at: [IndexPath(row: i, section: currentSection)], with: .automatic)
            }
            tableView.endUpdates();
        }

        // Expand/collapse the selected header depending on it's current state.
        currentHeader = header;
        data[section - 2].expanded = !data[section - 2].expanded;
        
        tableView.beginUpdates();
        for i in 0 ..< data[section - 2].gradeItems.count {
            tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .automatic)
        }
        tableView.endUpdates();
    }
}
