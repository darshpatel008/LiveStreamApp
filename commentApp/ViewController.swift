import UIKit
import AVKit

// MARK: - Data Models
struct User: Codable {
    let username: String
    let profilePictureURL: String
}

struct Comment: Codable {
    let username: String
    let profilePictureURL: String
    let text: String
}

struct VideoData: Codable {
    let videoURL: String
    let viewerCount: Int
    let likes: Int
    let comments: [Comment]
    let user: User
}

// MARK: - UITextField Extension for Padding
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

class ViewController: UIViewController {
    // MARK: - UI Components
    private let videoPlayerView = UIView()
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let followButton = UIButton()
    private let likeCountLabel = UILabel()
    private let viewerCountLabel = UILabel()
    private let liveBadgeLabel = UILabel()
    private let floatingCommentsStack = UIStackView()
    private let commentInputField = UITextField()
    private let heartButton = UIButton()
    private var videoPlayer: AVPlayer?
    private var recentlyDisplayedComments: Set<String> = []
    private var videoData: [VideoData] = []
    private var commentInputBottomConstraint: NSLayoutConstraint?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        loadData()
        setupVideoPlayer()
        scheduleFloatingComments()

        // Observe keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Load Data
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "DummyData", withExtension: "json") else {
            print("DummyData.json not found!")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            videoData = try decoder.decode([VideoData].self, from: data)
            updateUI(with: videoData.first) // Load the first video data
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Video Player View
        videoPlayerView.frame = view.bounds
        view.addSubview(videoPlayerView)

        // Profile Image
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImageView)

        // Username Label
        usernameLabel.textColor = .white
        usernameLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(usernameLabel)

        // Like Count Label
        likeCountLabel.textColor = .red
        likeCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        likeCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(likeCountLabel)

        // Follow Button
        followButton.setTitle("Follow", for: .normal)
        followButton.setTitleColor(.white, for: .normal)
        followButton.backgroundColor = .blue
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        followButton.layer.cornerRadius = 4
        followButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(followButton)

        // Viewer Count Label
        viewerCountLabel.textColor = .white
        viewerCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        viewerCountLabel.textAlignment = .center
        viewerCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewerCountLabel)

        // Live Badge
        liveBadgeLabel.text = "LIVE"
        liveBadgeLabel.textColor = .white
        liveBadgeLabel.backgroundColor = .red
        liveBadgeLabel.textAlignment = .center
        liveBadgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        liveBadgeLabel.layer.cornerRadius = 4
        liveBadgeLabel.clipsToBounds = true
        liveBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(liveBadgeLabel)

        // Floating Comments Stack
        floatingCommentsStack.axis = .vertical
        floatingCommentsStack.alignment = .leading
        floatingCommentsStack.spacing = 8
        floatingCommentsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatingCommentsStack)

        // Comment Input Field
        commentInputField.placeholder = "Write a comment..."
        commentInputField.textColor = .white
        commentInputField.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        commentInputField.font = UIFont.systemFont(ofSize: 14)
        commentInputField.layer.cornerRadius = 20
        commentInputField.clipsToBounds = true
        commentInputField.setLeftPaddingPoints(12)
        commentInputField.addTarget(self, action: #selector(handleSendComment), for: .editingDidEndOnExit)
        commentInputField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(commentInputField)

        // Heart Button
        heartButton.setTitle("❤️", for: .normal)
        heartButton.addTarget(self, action: #selector(handleHeartTap), for: .touchUpInside)
        heartButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartButton)

        setupConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleVideoTap))
        videoPlayerView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleVideoTap() {
        guard let videoPlayer = videoPlayer else { return }
        
        if videoPlayer.timeControlStatus == .playing {
            videoPlayer.pause()
        } else {
            videoPlayer.play()
        }
    }

    private func setupConstraints() {
        commentInputBottomConstraint = commentInputField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            // Profile Image
            profileImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),

            // Username Label
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            // Like Count Label
            likeCountLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            likeCountLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),

            // Follow Button
            followButton.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            followButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 60),
            followButton.heightAnchor.constraint(equalToConstant: 24),

            // Viewer Count Label
            viewerCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            viewerCountLabel.topAnchor.constraint(equalTo: liveBadgeLabel.bottomAnchor, constant: 4),

            // Live Badge
            liveBadgeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            liveBadgeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            liveBadgeLabel.widthAnchor.constraint(equalToConstant: 40),
            liveBadgeLabel.heightAnchor.constraint(equalToConstant: 20),

            // Floating Comments Stack
            floatingCommentsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floatingCommentsStack.bottomAnchor.constraint(equalTo: commentInputField.topAnchor, constant: -16),

            // Comment Input Field
            commentInputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commentInputField.trailingAnchor.constraint(equalTo: heartButton.leadingAnchor, constant: -8),
            commentInputBottomConstraint!,
            commentInputField.heightAnchor.constraint(equalToConstant: 40),

            // Heart Button
            heartButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            heartButton.centerYAnchor.constraint(equalTo: commentInputField.centerYAnchor),
            heartButton.widthAnchor.constraint(equalToConstant: 40),
            heartButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: - Update UI
    private func updateUI(with video: VideoData?) {
        guard let video = video else { return }
        usernameLabel.text = video.user.username
        likeCountLabel.text = "❤️ \(video.likes)"
        viewerCountLabel.text = "👁 \(video.viewerCount)"

        if let profileImage = UIImage(named: video.user.profilePictureURL) {
            profileImageView.image = profileImage
        } else {
            profileImageView.image = UIImage(systemName: "person.circle")
        }

        // Add floating comments
        floatingCommentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for comment in video.comments {
            addCommentToFloatingStack(comment: comment)
        }
    }

    private func addCommentToFloatingStack(comment: Comment) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8

        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 12
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        if let image = UIImage(named: comment.profilePictureURL) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(systemName: "person.circle")
        }

        let label = UILabel()
        label.text = "\(comment.username): \(comment.text)"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)

        stack.addArrangedSubview(profileImageView)
        stack.addArrangedSubview(label)
        floatingCommentsStack.addArrangedSubview(stack)

        // Ensure only the last three comments are visible
        if floatingCommentsStack.arrangedSubviews.count > 3 {
            if let firstSubview = floatingCommentsStack.arrangedSubviews.first {
                floatingCommentsStack.removeArrangedSubview(firstSubview)
                firstSubview.removeFromSuperview()
            }
        }
    }

    // MARK: - Schedule Floating Comments
    private func scheduleFloatingComments() {
        guard let firstVideo = videoData.first else { return }
        let comments = firstVideo.comments

        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            guard comments.count > currentIndex else {
                timer.invalidate()
                return
            }

            let comment = comments[currentIndex]
            self.addCommentToFloatingStack(comment: comment)
            currentIndex += 1
        }
    }

    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            commentInputBottomConstraint?.constant = -keyboardHeight - 8

            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }

            // Animate floating comments upward
            UIView.animate(withDuration: 0.3) {
                self.floatingCommentsStack.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight / 2)
            }
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        commentInputBottomConstraint?.constant = -16

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

        // Reset floating comments position
        UIView.animate(withDuration: 0.3) {
            self.floatingCommentsStack.transform = .identity
        }
    }

    // MARK: - Send Comment
    @objc private func handleSendComment() {
        guard let text = commentInputField.text, !text.isEmpty else { return }

        let newComment = Comment(username: "Darsh", profilePictureURL: "image7.png", text: text)
        addCommentToFloatingStack(comment: newComment)

        // Animate comments upward
        UIView.animate(withDuration: 0.5) {
            for subview in self.floatingCommentsStack.arrangedSubviews {
                subview.transform = CGAffineTransform(translationX: 0, y: -20)
            }
        } completion: { _ in
            self.floatingCommentsStack.arrangedSubviews.forEach { $0.transform = .identity }
        }

        // Clear the input field
        commentInputField.text = ""
    }

    // MARK: - Heart Animation
    @objc private func handleHeartTap() {
        let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
        heartImageView.tintColor = .red
        heartImageView.frame = CGRect(x: heartButton.center.x, y: heartButton.center.y, width: 40, height: 40)
        heartImageView.center = heartButton.center
        view.addSubview(heartImageView)

        UIView.animate(withDuration: 1.0, animations: {
            heartImageView.transform = CGAffineTransform(translationX: 0, y: -100).scaledBy(x: 2.0, y: 2.0)
            heartImageView.alpha = 0
        }, completion: { _ in
            heartImageView.removeFromSuperview()
        })
    }

    private func setupVideoPlayer() {
        guard let firstVideo = videoData.first, let url = Bundle.main.url(forResource: firstVideo.videoURL, withExtension: nil) else {
            print("Video file not found!")
            return
        }

        videoPlayer = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = videoPlayerView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoPlayerView.layer.addSublayer(playerLayer)

        videoPlayer?.play()
    }
}

