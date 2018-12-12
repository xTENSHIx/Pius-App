//
//  NewsTableView.swift
//  Pius-App
//
//  Created by Michael Mosler-Krings on 27.11.18.
//  Copyright © 2018 Felix Krings. All rights reserved.
//

import UIKit

protocol ShowNewsArticleDelegate {
    func prepareShow(of url: URL);
    func show();
}

class NewsTableView: UITableView, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, TodaySubTableViewDelegate {
    private var showNewsDelegate: ShowNewsArticleDelegate?;
    private var parentTableView: UITableView?;
    private let newsLoader = NewsLoader();
    private var newsItems: NewsItems?;

    func needsShow() -> Bool {
        return true;
    }

    private func doUpdate(with newsItems: NewsItems?, online: Bool) {
        if newsItems == nil {
            self.newsItems = [];
        } else {
            self.newsItems = newsItems;
        }
        
        DispatchQueue.main.async {
            self.dataSource = self;
            self.delegate = self;

            self.parentTableView?.beginUpdates();
            self.reloadData();
            self.layoutSubviews();
            self.parentTableView?.endUpdates();
        }
    }

    func loadData(showNewsDelegate delegate: ShowNewsArticleDelegate, sender: UITableView) {
        self.showNewsDelegate = delegate as? TodayTableViewController;
        self.parentTableView = sender;
        newsLoader.load(doUpdate);
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let newsItems = self.newsItems else { return 0; }
        return newsItems.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let newsItems = self.newsItems, let text = newsItems[indexPath.row].text else { return UITableViewCell(); }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsItem") as! NewsTableViewCell;

        if let imgUrl = newsItems[indexPath.row].imgUrl {
            do {
                let url = URL(string: imgUrl);
                let data = try Data(contentsOf : url!);
                let image = UIImage(data: data);
                cell.newsItemImageView.image = image;
            }
            catch {
                print("Failed to load image from \(imgUrl)");
            }
        }

        let itemText = NSMutableAttributedString(string: "");
        if let heading = newsItems[indexPath.row].heading {
            let headingFont = UIFont.systemFont(ofSize: 15, weight: .bold);
            itemText.append(NSAttributedString(string: heading, attributes: [NSAttributedString.Key.font: headingFont]));
            itemText.append(NSAttributedString(string: "\n"));
        }
        itemText.append(NSAttributedString(string: text));
        cell.newsItemTextLabel.attributedText = itemText;
        
        cell.href = newsItems[indexPath.row].href;
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? NewsTableViewCell, let href = cell.href, let url = URL(string: href) else { return; };

        showNewsDelegate?.prepareShow(of: url);
        showNewsDelegate?.show();
    }
}