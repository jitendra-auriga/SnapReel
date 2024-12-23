import UIKit
import AVKit
import Alamofire

// MARK: - Error Handling
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case serverError(String)
    
    var message: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No data received"
        case .decodingError: return "Error decoding data"
        case .serverError(let message): return message
        }
    }
}

// MARK: - View Controller
class VideoListViewController: UIViewController {
    
    // MARK: - Properties
    var tableView: UITableView!
    private var videos: [Video] = []
    private let refreshControl = UIRefreshControl()
    private var isLoading = false
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchVideos()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Videos"
        setupTableView()
        setupRefreshControl()
    }
    
    private func setupTableView() {
        print("Setting up TableView")
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")
        tableView.rowHeight = self.view.frame.height
        tableView.separatorStyle = .singleLine
        tableView.isPagingEnabled = true
        print("TableView setup completed")
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Data Fetching
    @objc private func refreshData() {
        print("Refreshing data...")
        fetchVideos()
    }
    
    private func fetchVideos() {
        guard !isLoading else {
            print("Already loading data, skipping fetch")
            return
        }
        
        isLoading = true
        showLoadingIndicator()
        
        let url = baseURL + "/api/get-videos"
        print("Fetching videos from: \(url)")
        AF.sessionConfiguration.timeoutIntervalForRequest = 60
        AF.request(url)
            .validate()
            .responseDecodable(of: VideoListBaseDM.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoading = false
                self.hideLoadingIndicator()
                self.refreshControl.endRefreshing()
                print("Status code -> ", response.response?.statusCode)
                switch response.result {
                case .success(let videoResponse):
                    print("Successfully fetched \(videoResponse.data.videos.count) videos")
                    self.handleSuccessResponse(videoResponse)
                    
                case .failure(let error):
                    print("Error fetching videos: \(error)")
                    self.handleError(error)
                }
            }
    }
    
    // MARK: - Response Handling
    private func handleSuccessResponse(_ response: VideoListBaseDM) {
        if response.success {
            self.videos = response.data.videos
            DispatchQueue.main.async {
                self.tableView.reloadData()
                print("TableView reloaded with \(self.videos.count) videos")
            }
        } else {
            print("API returned success: false with message: \(response.message)")
            showAlert(title: "Error", message: response.message)
        }
    }
    
    private func handleError(_ error: AFError) {
        let message: String
        switch error {
        case .invalidURL(let url):
            message = "Invalid URL: \(url)"
        case .responseValidationFailed(let reason):
            message = "Validation failed: \(reason)"
        case .responseSerializationFailed(let reason):
            message = "Serialization failed: \(reason)"
        default:
            message = error.localizedDescription
        }
        
        showAlert(title: "Error", message: message)
    }

    
    // MARK: - UI Helpers
    private func showLoadingIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.tag = 999
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        view.viewWithTag(999)?.removeFromSuperview()
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - TableView Delegate & DataSource
extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Configuring cell for row: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        if let videoURL = URL(string: baseURL + "/" + (videos[indexPath.row].path ?? "") ?? "") {
            cell.configure(with: videoURL, tag: indexPath.row,cell: cell, videoT: videos[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let videoCell = tableView.cellForRow(at: indexPath) as? VideoCell else { return }
        let video = videos[indexPath.row]
        print("Will display video cell at index: \(indexPath.row), Video ID: \(video.id)")
//        playVideo(for: videoCell, video: video)

    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height
    }
}


// MARK: - Video Cell
class VideoCell: UITableViewCell {
    
    // MARK: - Properties
    private var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    private var thumbnailImageView: UIImageView!
    private var playButton: UIButton!
    private var isPlaying = false
    private var video: Video?
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        // Setup thumbnail image view to fill the entire cell
        thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.backgroundColor = .black
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        
        // Setup play button
        playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 72))
            .withRenderingMode(.alwaysTemplate),
            for: .normal)
        playButton.tintColor = .white
        playButton.alpha = 0.8
        playButton.contentVerticalAlignment = .fill
        playButton.contentHorizontalAlignment = .fill
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        contentView.addSubview(playButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Make thumbnail fill the entire cell
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Center play button
            playButton.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 72),
            playButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    // MARK: - Configuration
    func configure(with videoURL: URL, tag: Int, cell: VideoCell, videoT: Video) {
        video = videoT
            cell.playButton.tag = tag
//        generateThumbnail(from: videoURL) { [weak self] image in
//            DispatchQueue.main.async {
//                self?.thumbnailImageView.image = image
//            }
//        }
        ImageCacheManager.shared.getImage(for: videoURL) { [weak self] image in
                    DispatchQueue.main.async {
                        self?.thumbnailImageView.image = image
                    }
                }
        
        // Setup player
        let player = AVPlayer(url: videoURL)
        self.player = player
        
        if playerLayer == nil {
            let layer = AVPlayerLayer(player: player)
            layer.frame = thumbnailImageView.bounds
            layer.videoGravity = .resizeAspectFill
            layer.isHidden = true
            thumbnailImageView.layer.addSublayer(layer)
            playerLayer = layer
        }
        
        // Add observer for video completion
        NotificationCenter.default.addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)
    }
    
    private func generateThumbnail(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } catch {
                print("Error generating thumbnail: \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func playButtonTapped(sender: UIButton) {
        
        let playerViewController = AVPlayerViewController()
        if let ulr = URL(string: baseURL + "/" + (self.video?.path ?? "")) {
            playerViewController.player = AVPlayer(url: ulr)
            playerViewController.modalPresentationStyle = .fullScreen
            self.window?.rootViewController?.present(playerViewController, animated: true , completion: nil)
        }
        
                playerViewController.modalPresentationStyle = .fullScreen
        if isPlaying {
            player?.pause()
            showPlayButton()
        } else {
            player?.play()
            hidePlayButton()
        }
        
        playerLayer?.isHidden = false
        isPlaying.toggle()
    }
    
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        showPlayButton()
        player?.seek(to: .zero)
    }
    
    private func showPlayButton() {
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = 0.8
            self.playButton.setImage(UIImage(systemName: "play.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 72))
                .withRenderingMode(.alwaysTemplate),
                for: .normal)
        }
    }
    
    private func hidePlayButton() {
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = 0
            self.playButton.setImage(UIImage(systemName: "pause.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 72))
                .withRenderingMode(.alwaysTemplate),
                for: .normal)
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = thumbnailImageView.bounds
    }
    
    // MARK: - Cleanup
    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        thumbnailImageView.image = nil
        isPlaying = false
        showPlayButton()
        NotificationCenter.default.removeObserver(self)
    }
}
// MARK: - Helper Extensions
extension TimeInterval {
    func formatDuration() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
class RecordButton: UIButton {
    private let progressLayer = CAShapeLayer()
    private var timer: Timer?
    private var currentTime: TimeInterval = 0
    private let maxDuration: TimeInterval = 30
    var recordStarted: ((UIButton) -> Void)?
    var recordFinished: ((UIButton) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        backgroundColor = .white
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = 3
        layer.borderColor = UIColor.green.cgColor
        
        // Setup progress layer
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                                      radius: bounds.width / 2,
                                      startAngle: -CGFloat.pi / 2,
                                      endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
                                      clockwise: true)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.red.cgColor
        progressLayer.lineWidth = 3
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    func startRecording() {
        currentTime = 0
        recordStarted?(self)
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.currentTime += 0.1
            let progress = min(self.currentTime / self.maxDuration, 1.0)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.progressLayer.strokeEnd = CGFloat(progress)
            CATransaction.commit()
            
            if self.currentTime >= self.maxDuration {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        UIView.animate(withDuration: 0.3) {
            self.progressLayer.strokeEnd = 0
        }
        currentTime = 0
        recordFinished?(self)
    }
}
class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    private var loadingOperations: [String: Operation] = [:]
    private let loadingQueue = OperationQueue()
    
    private init() {
        // Configure cache
        cache.countLimit = 100 // Maximum number of images
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
    }
    
    func getImage(for url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // Check if image is in cache
        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // Check if there's already a loading operation for this URL
        if loadingOperations[url.absoluteString] != nil {
            return
        }
        
        // Create new loading operation
        let operation = ThumbnailGenerationOperation(videoURL: url) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }
            
            self.cache.setObject(image, forKey: key)
            self.loadingOperations.removeValue(forKey: url.absoluteString)
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        loadingOperations[url.absoluteString] = operation
        loadingQueue.addOperation(operation)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func cancelAllOperations() {
        loadingQueue.cancelAllOperations()
        loadingOperations.removeAll()
    }
}

// Custom Operation for generating thumbnails
class ThumbnailGenerationOperation: Operation {
    private let videoURL: URL
    private let completion: (UIImage?) -> Void
    
    init(videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        self.videoURL = videoURL
        self.completion = completion
        super.init()
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            completion(thumbnail)
        } catch {
            print("Error generating thumbnail: \(error)")
            completion(nil)
        }
    }
}
