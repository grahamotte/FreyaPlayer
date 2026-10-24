import UIKit

final class PosterCell: UICollectionViewCell {
    enum CaptionMode {
        case always
        case focused
    }

    static let reuseIdentifier = "PosterCell"

    private let imageView = UIImageView()
    private let progressView = ArtworkProgressIndicatorView()
    private let placeholderStack = UIStackView()
    private let iconView = UIImageView()
    private let placeholderLabel = UILabel()
    private let titleLabel = MarqueeLabel()
    private let subtitleLabel = UILabel()
    private let artworkLoader = ArtworkImageLoader()
    private var imageHeightConstraint: NSLayoutConstraint!
    private var captionMode = CaptionMode.always
    private var showsSubtitle = true

    static func captionHeight(showsSubtitle: Bool) -> CGFloat {
        let title = PlatformMetadata.uiTileTitleFont.lineHeight
        let subtitle = showsSubtitle ? PlatformMetadata.tileSubtitleSpacing + PlatformMetadata.uiLabelFont.lineHeight : 0
        return ceil(PlatformMetadata.tileTitleSpacing + title + subtitle + AppTheme.Spacing.small)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        contentView.clipsToBounds = false
        backgroundConfiguration = .clear()

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = false
        imageView.layer.cornerRadius = AppTheme.Radius.artwork
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFill
        PlatformMetadata.configureFocusedImageView(imageView)

        iconView.tintColor = AppTheme.uiSecondaryText
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title2, scale: .medium)

        placeholderLabel.font = PlatformMetadata.uiTileTitleFont
        placeholderLabel.textColor = AppTheme.uiSecondaryText
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 2

        placeholderStack.axis = .vertical
        placeholderStack.alignment = .center
        placeholderStack.spacing = AppTheme.Spacing.small
        placeholderStack.translatesAutoresizingMaskIntoConstraints = false
        placeholderStack.addArrangedSubview(iconView)
        placeholderStack.addArrangedSubview(placeholderLabel)

        let overlay = PlatformMetadata.overlayContent(for: imageView)
        overlay.addSubview(placeholderStack)
        progressView.pin(inside: overlay)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = PlatformMetadata.uiTileTitleFont
        titleLabel.textColor = AppTheme.uiPrimaryText

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = PlatformMetadata.uiLabelFont
        subtitleLabel.textColor = AppTheme.uiSecondaryText
        subtitleLabel.numberOfLines = 1

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
        let captionTop = PlatformMetadata.focusedBottomAnchor(for: imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageHeightConstraint,

            placeholderStack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            placeholderStack.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: AppTheme.Spacing.medium),
            placeholderStack.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -AppTheme.Spacing.medium),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: captionTop, constant: PlatformMetadata.tileTitleSpacing),
            titleLabel.heightAnchor.constraint(equalToConstant: ceil(PlatformMetadata.uiTileTitleFont.lineHeight)),

            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: PlatformMetadata.tileSubtitleSpacing)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        subtitle: String?,
        artworkURL: URL?,
        style: MediaArtworkStyle,
        progress: Double?,
        isWatched: Bool,
        placeholderIcon: String? = nil,
        placeholderTitle: String? = nil,
        captionMode: CaptionMode
    ) {
        self.captionMode = captionMode
        showsSubtitle = subtitle != nil
        accessibilityLabel = [title, subtitle].compactMap { $0 }.joined(separator: ", ")
        titleLabel.text = placeholderTitle == nil ? title : nil
        subtitleLabel.text = subtitle
        iconView.image = UIImage(systemName: placeholderIcon ?? style.placeholderIconName)
        placeholderLabel.text = placeholderTitle
        placeholderLabel.isHidden = placeholderTitle == nil
        progressView.setProgress(progress, isWatched: isWatched)
        updateCaption(isFocused: isFocused)
        setNeedsLayout()

        artworkLoader.load(artworkURL) { [weak self] image in
            self?.showArtwork(image)
        }
    }

    private func showArtwork(_ image: UIImage?) {
        imageView.image = image ?? ArtworkImageLoader.placeholderImage
        placeholderStack.isHidden = image != nil
    }

    private func updateCaption(isFocused: Bool) {
        let isVisible = captionMode == .always || isFocused
        titleLabel.alpha = isVisible ? 1 : 0
        subtitleLabel.alpha = isVisible ? 1 : 0
        titleLabel.setMarqueeActive(isFocused)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        imageHeightConstraint.constant = layoutAttributes.size.height - Self.captionHeight(showsSubtitle: showsSubtitle)
    }

    override func layoutSubviews() {
        imageHeightConstraint.constant = bounds.height - Self.captionHeight(showsSubtitle: showsSubtitle)
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.setMarqueeActive(false)
        artworkLoader.reset()
        showArtwork(nil)
        progressView.setProgress(nil, isWatched: false)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        let isFocused = self.isFocused
        coordinator.addCoordinatedAnimations {
            self.updateCaption(isFocused: isFocused)
        }
    }
}
