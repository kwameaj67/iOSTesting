//
//  ViewController.swift
//  miniBootcampChallenge
//

import UIKit

class ViewController: UICollectionViewController {
    
    private struct Constants {
        static let title = "Mini Bootcamp Challenge"
        static let cellID = "imageCell"
        static let cellSpacing: CGFloat = 1
        static let columns: CGFloat = 3
        static var cellSize: CGFloat?
    }
    
    private lazy var urls: [URL] = URLProvider.urls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.title
    }
    
    
}


// TODO: 1.- Implement a function that allows the app downloading the images without freezing the UI or causing it to work unexpected way
func downloadImage(imageURL: URL, completion: @escaping (Data?,Error?) -> Void){
    let session = URLSession.init(configuration: URLSessionConfiguration.default)
    let task = session.downloadTask(with: imageURL) { data, response, error in
        if let error = error {
            completion(nil,error)
            return
        }
        
        guard let data = data else {
            return
        }
        
        do {
            let photo = try Data(contentsOf: data)
            completion(photo,nil)
            print("Donwload done")
        }
        catch let error{
            completion(nil,error)
        }
    }
    task.resume()
}

// TODO: 2.- Implement a function that allows to fill the collection view only when all photos have been downloaded, adding an animation for waiting the completion of the task.


// MARK: - UICollectionView DataSource, Delegate
extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        urls.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as? ImageCell else { return UICollectionViewCell() }
        
        // placeholder image
        cell.imageView.image = UIImage(named: "placeholder")?.withRenderingMode(.alwaysOriginal)
        
        let url = urls[indexPath.row]
        
        // download remote image
        downloadImage(imageURL: url) { data, error in
            // get UIImage from data object
            let photo = self.getImageFromData(data: data)
            
            // update ui(photo) on main thread
            DispatchQueue.main.async {
                cell.display(photo)
            }
            
        }
        return cell
    }
    
    // unwrap data for image
    func getImageFromData(data: Data?) -> UIImage? {
        if let data = data {
            return UIImage(data: data)
        }
        // incase data is nil, use placeholder image regardless
        return UIImage(named: "placeholder")?.withRenderingMode(.alwaysOriginal)
    }
}


// MARK: - UICollectionView FlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if Constants.cellSize == nil {
          let layout = collectionViewLayout as! UICollectionViewFlowLayout
            let emptySpace = layout.sectionInset.left + layout.sectionInset.right + (Constants.columns * Constants.cellSpacing - 1)
            Constants.cellSize = (view.frame.size.width - emptySpace) / Constants.columns
        }
        return CGSize(width: Constants.cellSize!, height: Constants.cellSize!)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }
}
