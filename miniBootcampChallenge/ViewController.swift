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
    
    private lazy var urls = URLProvider.urls
    
    // new properties added
    private lazy var photos = [Data]()
    var isDownloadAllData = false
    let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.title
        
        // uncomment this function below to fill the collection view only when all photos have been downloaded
        //downloadAllData()
    }
}

// TODO: 1.- Implement a function that allows the app downloading the images without freezing the UI or causing it to work unexpected way
// MARK: UIImageView (downloadImage) -
extension UIImageView {
    func downloadImage(imageURL: URL){
        let cache = NSCache<NSString, NSData>()
        
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        
        let task = session.downloadTask(with: imageURL) { data, response, error in
            if let cachedData = cache.object(forKey: imageURL.absoluteString as NSString){ // check the cache
                print("using cached images \(cachedData.count)")
                
                let image = self.getImageFromData(data: cachedData as Data)
                DispatchQueue.main.async() { [weak self] in
                    self?.image = image
                }
            }
            else {
                if let error = error {
                    print("\(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let photoURL = try Data(contentsOf: data)
                    cache.setObject(photoURL as NSData, forKey: imageURL.absoluteString as NSString)
            
                    let image = self.getImageFromData(data: photoURL)
                    DispatchQueue.main.async() { [weak self] in
                        self?.image = image
                    }
                    print("\(photoURL.count) Donwload done")
                }
                catch let error{
                    print("\(error.localizedDescription)")
                }
            }
        }
        task.resume()
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

// TODO: 2.- Implement a function that allows to fill the collection view only when all photos have been downloaded, adding an animation for waiting the completion of the task.
// MARK: ViewController (downloadAllData) -
extension ViewController {
    func downloadAllData(){
        
        // notifies collectionView if we downloading all data
        isDownloadAllData = true
        
        // parallel async downloading of images.  since task is async, any image to download first would be populated into the collectionView
        for url in urls {
            self.dispatchGroup.enter()
            downloadAllImages(imageURL: url) { data, error in
                self.dispatchGroup.leave()
                
                if let err = error {
                    print("\(err.localizedDescription)")
                }
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    self.photos.append(data) // populate downloaded image
                }
            }
        }
        
        self.dispatchGroup.notify(queue: .main){
            //All images has been downloaded here
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func downloadAllImages(imageURL: URL, completion: @escaping (Data?, Error?) -> Void){
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        let task = session.downloadTask(with: imageURL) { data, response, error in
            if let error = error {
                print("\(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let photoURL = try Data(contentsOf: data)
                completion(photoURL,nil)
                print("\(photoURL.count) downloading done")
            }
            catch let error{
                print("\(error.localizedDescription)")
            }
        }
        task.resume()
    }
}


// MARK: - UICollectionView DataSource, Delegate
extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isDownloadAllData ? photos.count :  urls.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as? ImageCell else { return UICollectionViewCell() }
        
        if isDownloadAllData {
            let data = photos[indexPath.row]
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                cell.display(image)
            }
            return cell
        }
        else {
            // placeholder image
            cell.imageView.image = UIImage(named: "placeholder")?.withRenderingMode(.alwaysOriginal)
            let url = urls[indexPath.row]
            cell.imageView.downloadImage(imageURL: url)
            return cell
        }
        
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
