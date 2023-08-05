import UIKit
import SwiftUI
import SnapKit

public struct BottomSheetHostingView<Content: View>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = BottomSheetController
    
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    public func makeUIViewController(context: Context) -> BottomSheetController {
        let vc = HostingBottomSheet<Content>()
        vc.hosting = UIHostingController(rootView: content())
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: BottomSheetController, context: Context) {
        
    }
}

public protocol BottomSheet: UIViewController {
    var contentView: UIView { get }
}

public class BottomSheetControllerHandler: NSObject, UIGestureRecognizerDelegate {
    fileprivate static let propotionOfContentViewHeigth: CGFloat = 1
    private weak var _controller: BottomSheet?
    private var delegate = BottomSheetTransisitioningDelegate()
    private var _percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition? = nil {
        didSet {
            delegate._percentDrivenInteractiveTransition = _percentDrivenInteractiveTransition
        }
    }
    private weak var _bottomInsetsView: UIView?
    var insetViewBackgroundColor: UIColor = .white {
        didSet {
            _bottomInsetsView?.backgroundColor = insetViewBackgroundColor
        }
    }
    
    var canHideOutsideTap: Bool = true
    var disablePanGesture: Bool = false {
        didSet {
            _panGesture?.isEnabled = !disablePanGesture
        }
    }
    
    var userInitiatedDismissCallback: (()->Void)?
    var heigthOfView: CGFloat!
    var percentageCompleted:CGFloat = 0.0
    public init(of controller: BottomSheet ) {
        self._controller = controller
    }
    
    public func awaked() {
        _controller?.transitioningDelegate = delegate
        _controller?.modalPresentationStyle = .overCurrentContext
        _controller?.definesPresentationContext = true
    }
    
    private weak var _panGesture: UIPanGestureRecognizer?
    
    public func didLoaded() {
        let panGesture = UIPanGestureRecognizer()
        _controller?.contentView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(handle(gesture:)))
        let tapGestrue = UITapGestureRecognizer(target: self, action: #selector(_dismissSelf(_:)))
        tapGestrue.cancelsTouchesInView = false;
        _controller?.view.addGestureRecognizer(tapGestrue)
        panGesture.delegate = self
        _addBottomInsetView()
        self._panGesture = panGesture
    }
    
    private func _addBottomInsetView() {
        guard let controller = _controller else {
            return
        }
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = insetViewBackgroundColor
        controller.view.addSubview(view)
        view.topAnchor.constraint(equalTo: controller.contentView.bottomAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: controller.view.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: controller.view.rightAnchor).isActive = true
        _bottomInsetsView = view
    }
    
    @objc
    func handle(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            _percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
            _percentDrivenInteractiveTransition?.completionSpeed = 1
            _percentDrivenInteractiveTransition?.timingCurve = UISpringTimingParameters()
            heigthOfView = (_controller?.contentView.frame.height)!
            _controller?.dismiss(animated: true, completion: nil)
        } else if gesture.state == .changed {
            let translation = gesture.translation(in: _controller?.contentView)
            percentageCompleted = CGFloat(fminf(fmaxf(Float(translation.y / (heigthOfView * BottomSheetControllerHandler.propotionOfContentViewHeigth )), 0.0), 1.0))
            _percentDrivenInteractiveTransition?.update(percentageCompleted)
        } else if gesture.state == .ended {
            let velocity:Int = Int(gesture.velocity(in: nil).y)
            if percentageCompleted > 0.45 || velocity > 1800 {
                _percentDrivenInteractiveTransition?.finish()
                userInitiatedDismissCallback?()
            } else {
                _percentDrivenInteractiveTransition?.cancel()
            }
            _percentDrivenInteractiveTransition = nil
        } else if gesture.state == .cancelled {
            _percentDrivenInteractiveTransition?.cancel()
            _percentDrivenInteractiveTransition = nil
        }
    }
    
    @objc func _dismissSelf(_ tapGesture: UITapGestureRecognizer) {
        if !canHideOutsideTap { return }
        let locationInControllerView = tapGesture.location(in: _controller?.view)
        if let contentView = _controller?.contentView, contentView.frame.contains(locationInControllerView) {
            return
        }
        _controller?.dismiss(animated: true, completion: {
            self.userInitiatedDismissCallback?()
        })
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self._panGesture, let panGesture = _panGesture {
            let translation = panGesture.translation(in: nil)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView, scrollView.contentOffset.y <= 0 {
            return true
        }
        return false
    }
}

open class BottomSheetController: UIViewController, BottomSheet {
    public var contentView: UIView {
        guard let v = contentViewOutlet else {
            fatalError("Please provide content view")
        }
        return v
    }
    
    private(set) lazy var handler = BottomSheetControllerHandler(of: self)
    @IBOutlet var contentViewOutlet: UIView?
    private var awaked = false
    
    open var canDismissmissOutsideTap: Bool {
        get {
            return handler.canHideOutsideTap
        }
        set {
            handler.canHideOutsideTap = newValue
        }
    }
    
    open var disablePanGesture: Bool {
        get {
            handler.disablePanGesture
        }
        set {
            handler.disablePanGesture = newValue
        }
    }
   
    open override func awakeFromNib() {
        super.awakeFromNib()
        handler.awaked()
        awaked = true
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        handler.didLoaded()
    }
    
    open var insetsBackgroundColor: UIColor = .white {
        didSet {
            handler.insetViewBackgroundColor = insetsBackgroundColor
        }
    }
}

fileprivate class BottomSheetTransisitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    fileprivate var _percentDrivenInteractiveTransition :UIPercentDrivenInteractiveTransition?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetTransisitioningAnimation(isPresenting: true, interactive: false)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetTransisitioningAnimation(isPresenting: false, interactive: _percentDrivenInteractiveTransition != nil)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return _percentDrivenInteractiveTransition
    }
}

class BottomSheetTransisitioningAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var _isPresenting: Bool
    private var _interactive: Bool
    
    init(isPresenting: Bool, interactive: Bool) {
        self._isPresenting = isPresenting
        self._interactive = interactive
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        var bottomSheetController = _isPresenting ? toViewController : fromViewController
        if let navController = bottomSheetController.navigationController {
            bottomSheetController = navController.viewControllers.first!
        }
        transitionContext.containerView.addSubview(bottomSheetController.view)
        
        guard let contentView = (bottomSheetController as? BottomSheet)?.contentView else {
            fatalError(String(describing: bottomSheetController) + "Not Confirming BottomSheet Protocol")
        }
        let method = _isPresenting ? self._presentAnimation : self._dismissAnimation
        contentView.layoutIfNeeded()
        let height = contentView.bounds.height * BottomSheetControllerHandler.propotionOfContentViewHeigth
        method(transitionContext,bottomSheetController, contentView, height)
    }
    
    private func _presentAnimation(transitionContext: UIViewControllerContextTransitioning, bottomSheetController:UIViewController , contentView: UIView, contentViewAnimationHeight: CGFloat) {
        contentView.transform = CGAffineTransform(translationX: 0, y: contentViewAnimationHeight)
        
        let toViewBackgroundColor = UIColor.black.withAlphaComponent(0.6)
        bottomSheetController.view.backgroundColor = .clear
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            bottomSheetController.view.backgroundColor = toViewBackgroundColor
            contentView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    private func _dismissAnimation(transitionContext: UIViewControllerContextTransitioning, bottomSheetController:UIViewController , contentView: UIView, contentViewAnimationHeight: CGFloat) {
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            bottomSheetController.view.backgroundColor = .clear
            contentView.alpha = 1
            contentView.transform = CGAffineTransform(translationX: 0, y: contentViewAnimationHeight)
        }) { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
}

open class BottomSheetSwiftUIVC<Content: View> : BottomSheetController {
    
    private var topInset: CGFloat = 80
    
    var c: () -> Content
    
    public override var contentView: UIView {
        view.subviews.first!
    }
    
    public init(topInsets: CGFloat? = nil, content: @escaping () -> Content) {
        self.c = content
        super.init(nibName: nil, bundle: nil)
        if let topInsets {
            self.topInset = topInsets
        }
        awakeFromNib()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addContent() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualTo(self.view.snp.topMargin).inset(max(topInset, 44))
        }
        return view
    }
    
    open override func viewDidLoad() {
        let hosting = SelfSizingHostingController(rootView: c())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        let v = addContent()
        v.addSubview(hosting.view)
        hosting.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        super.viewDidLoad()
    }
}

class SelfSizingHostingController<Content>: UIHostingController<Content> where Content: View {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize()
    }
}

public class HostingBottomSheet<Content: View>: BottomSheetController {
    
    weak var contentInternal: UIView!
    var hosting: UIHostingController<Content>!
    
    public override var contentView: UIView {
        contentInternal
    }
    
    func addContent() {
        let view = UIView()
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentInternal = view
    }
    
    public override func viewDidLoad() {
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        addContent()
        contentInternal.addSubview(hosting.view)
        hosting.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        super.viewDidLoad()
    }
    
}
