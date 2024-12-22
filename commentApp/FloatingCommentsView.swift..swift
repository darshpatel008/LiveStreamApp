import UIKit

class FloatingCommentsView: UIView {
    struct Comment {
        let username: String
        let profilePictureURL: String
        let text: String
    }

    var comments: [Comment] = [] {
        didSet {
            if !comments.isEmpty {
                startDisplayingComments()
            }
        }
    }

    private var currentCommentIndex = 0
    private let commentDisplayInterval: TimeInterval = 1.5 // Faster time between comments appearing
    private let animationDuration: TimeInterval = 2.5 // Smooth duration for upward animation

    private func startDisplayingComments() {
        guard !comments.isEmpty else { return }
        displayNextComment()
    }

    private func displayNextComment() {
        let comment = comments[currentCommentIndex]

        // Create the container view
        let commentView = UIView()
        commentView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        commentView.layer.cornerRadius = 20
        commentView.clipsToBounds = true

        // Add profile image
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        if let image = UIImage(named: comment.profilePictureURL) {
            imageView.image = image
        }

        // Add username label
        let usernameLabel = UILabel()
        usernameLabel.text = comment.username
        usernameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        usernameLabel.textColor = .white

        // Add comment text label
        let commentLabel = UILabel()
        commentLabel.text = comment.text
        commentLabel.font = UIFont.systemFont(ofSize: 14)
        commentLabel.textColor = .white

        // Arrange views in a horizontal stack
        let stackView = UIStackView(arrangedSubviews: [imageView, usernameLabel, commentLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        commentView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: commentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: commentView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: commentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: commentView.bottomAnchor, constant: -8)
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Add the comment view to the main view
        addSubview(commentView)
        commentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            commentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            commentView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.8),
            commentView.topAnchor.constraint(equalTo: self.topAnchor, constant: -50) // Start slightly above the screen
        ])

        // Animate the comment view upwards
        layoutIfNeeded()
        UIView.animate(withDuration: animationDuration, animations: {
            commentView.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
            commentView.alpha = 0
        }, completion: { _ in
            commentView.removeFromSuperview()
        })

        // Schedule the next comment
        currentCommentIndex = (currentCommentIndex + 1) % comments.count
        DispatchQueue.main.asyncAfter(deadline: .now() + commentDisplayInterval) {
            self.displayNextComment()
        }
    }

}

