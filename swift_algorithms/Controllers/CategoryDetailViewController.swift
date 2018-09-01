import UIKit
import Anchorage
import Hero

class View: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewDidLoad()
    }
    
    func viewDidLoad() {}
    
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while responder is UIView {
            responder = responder!.next
        }
        return responder as? UIViewController
    }
    
}

final class CategoryDetailView: View {
    
    let cardView = CategoryTileItemView()
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let status = UIApplication.shared.statusBarFrame.height
        cardView.verticalOffset = status + 36
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundColor = .white
        
        cardView.layer.cornerRadius = 0
        cardView.layer.shadowColor = UIColor.clear.cgColor
        
        addSubview(tableView)
        addSubview(cardView)
        
        tableView.hero.modifiers = [.useNoSnapshot, .translate(y: -80), .fade]
        
        cardView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(gr:))))
    }
    @objc func pan(gr: UIPanGestureRecognizer) {
        let translation = gr.translation(in: self)
        switch gr.state {
        case .began:
            parentViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            Hero.shared.update(translation.y / bounds.height)
        default:
            let velocity = gr.velocity(in: self)
            if ((translation.y + velocity.y) / bounds.height) > 0.5 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let headerHeight: CGFloat = 140
        cardView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: headerHeight)
        tableView.frame = CGRect(x: 0, y: headerHeight, width: bounds.width, height: bounds.height - headerHeight)
    }
}

final class CategoryDetailViewController: UIViewController {
    
    let detail = CategoryDetailView()
    let back = UIButton()
    var onSelect: ((UUID) -> Void)?
    
    var sections: [TableSectionController] = [] {
        didSet {
            update(with: sections)
        }
    }
    
    private func update(with sections: [TableSectionController]) {
        sections.forEach { section in
            section.registerReusableTypes(tableView: detail.tableView)
            
            section.onSelect = { [weak self] identifier in
                self?.onSelect?(identifier)
            }
        }
        
        detail.tableView.reloadData()
    }
    
    override func loadView() {
        view = detail
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hero.isEnabled = true
        detail.tableView.delegate = self
        detail.tableView.dataSource = self
        detail.tableView.backgroundColor = UIColor.groupTableViewBackground
        
        back.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysTemplate), for: .normal)
        back.tintColor = .white
        back.imageView?.contentMode = .scaleAspectFit
        
        detail.cardView.addSubview(back)
        back.leadingAnchor == detail.cardView.leadingAnchor + 8
        back.centerYAnchor == detail.cardView.centerYAnchor - 8
        back.sizeAnchors == CGSize(width: 24, height: 24)
        back.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        
    }
    
    @objc func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension CategoryDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].tableView(tableView, numberOfRowsInSection: section)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (sections[section].tableView?(tableView, heightForHeaderInSection: section)) ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].tableView?(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sections[indexPath.section].tableView?(tableView, didSelectRowAt: indexPath)

        //Change the selected background view of the cell after selection.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sections[indexPath.section].tableView?(tableView, heightForRowAt: indexPath) ?? UITableViewAutomaticDimension
    }
}


final class RoundedCardWrapperView: View {
    let cardView = CategoryTileItemView()
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubview(cardView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if cardView.superview == self {
            // this is necessary because we used useNoSnapshot modifier.
            // we don't want cardView to be resized when Hero is using it for transition
            cardView.frame = bounds
        }
    }
}