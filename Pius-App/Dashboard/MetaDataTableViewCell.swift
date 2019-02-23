//
//  MetaDataTableCellTableViewCell.swift
//  Pius-App
//
//  Created by Michael Mosler-Krings on 24.10.18.
//  Copyright © 2018 Felix Krings. All rights reserved.
//

import UIKit

class MetaDataTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var tickerText: String?;
    private var additionalText: String?;
    private var cells: [MetaDataCollectionViewCell?] = [nil, nil];
    
    override func awakeFromNib() {
        super.awakeFromNib();
        collectionView.delegate = self;
        collectionView.dataSource = self;
        flowLayout.itemSize = CGSize(width: CGFloat(IOSHelper.screenWidth), height: flowLayout.itemSize.height);
        pageControl.numberOfPages = 1;
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageControl.numberOfPages;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cells[indexPath.row] = collectionView.dequeueReusableCell(withReuseIdentifier: "metaDataCollectionViewCell", for: indexPath) as? MetaDataCollectionViewCell;
        setContent(tickerText: tickerText, additionalText: additionalText);
        return cells[indexPath.row]!;
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = round(scrollView.contentOffset.x / CGFloat(IOSHelper.screenWidth));
        pageControl.currentPage = Int(currentPage);
    }
    
    private func setCellContent(_ tickerText: String?, _ additionalText: String!) {
        pageControl.numberOfPages = (additionalText == "") ? 1 : 2;

        if let cell = cells[0] {
            cell.metaDataTextLabel.text = tickerText;
        }
        
        if let cell = cells[1] {
            cell.metaDataTextLabel.text = additionalText;
        }
    }
    
    func setContent(tickerText: String!, additionalText: String!) {
        self.tickerText = tickerText;
        self.additionalText = additionalText;
        setCellContent(tickerText, additionalText)
    }
}
