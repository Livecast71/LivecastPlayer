#if canImport(UIKit)
import UIKit

final class LivecastMiniPlayerBarView: UIView {

    private let effectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemChromeMaterial)
        return UIVisualEffectView(effect: blur)
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .label
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let playingIndicator: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.tintColor = .systemBlue
        v.contentMode = .scaleAspectFit
        return v
    }()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.layer.cornerRadius = 16
        effectView.clipsToBounds = true
        addSubview(effectView)
        effectView.contentView.addSubview(playingIndicator)
        effectView.contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            playingIndicator.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 16),
            playingIndicator.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor),
            playingIndicator.widthAnchor.constraint(equalToConstant: 28),
            playingIndicator.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: playingIndicator.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    @objc private func handleTap() {
        onTap?()
    }
}
#endif
