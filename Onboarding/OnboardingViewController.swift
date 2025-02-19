import UIKit

protocol OnboardingControllerDelegate: class {
    func onboardingDismissed ()
}

class OnboardingController: UIViewController, UIScrollViewDelegate {
    weak var delegate:OnboardingControllerDelegate?
    let backgroundColor = UIColor(red: 52.0/255.0, green: 73.0/255.0, blue: 94.0/255.0, alpha: 1.0)
    let slides = [
        [ "image": "Simulator Screen Shot 31 янв. 2016 г., 11.17.11.png", "text": "Создавайте заказ в пару касаний"],
        [ "image": "Simulator Screen Shot 31 янв. 2016 г., 14.14.40.png", "text": "Определяйте свой адрес на карте"],
        [ "image": "Simulator Screen Shot 31 янв. 2016 г., 14.13.51.png", "text": "Вам понравился водитель? Расскажите об этом всем!"],
        [ "image": "Simulator Screen Shot 31 янв. 2016 г., 14.07.36.png", "text": "Отслеживайте водителя и себя на карте"],
    ]
    let screen: CGRect = UIScreen.mainScreen().bounds
    var scroll: UIScrollView?
    var dots: UIPageControl?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        scroll = UIScrollView(frame: CGRect(x: 0.0, y: 0.0, width: screen.width, height: screen.height * 0.9))
        scroll?.showsHorizontalScrollIndicator = false
        scroll?.showsVerticalScrollIndicator = false
        scroll?.pagingEnabled = true
        view.addSubview(scroll!)
        if (slides.count > 1) {
            dots = UIPageControl(frame: CGRect(x: 0.0, y: screen.height * 0.875, width: screen.width, height: screen.height * 0.05))
            dots?.numberOfPages = slides.count
            view.addSubview(dots!)
        }
        for var i = 0; i < slides.count; ++i {
            if let image = UIImage(named: slides[i]["image"]!) {
                let imageView: UIImageView = UIImageView(frame: getFrame(image.size.width, iH: image.size.height, slide: i, offset: screen.height * 0.15))
                imageView.image = image
                scroll?.addSubview(imageView)
            }
            if let text = slides[i]["text"] {
                let textView = UITextView(frame: CGRect(x: screen.width * 0.05 + CGFloat(i) * screen.width, y: screen.height * 0.745, width: screen.width * 0.9, height: 100.0))
                textView.text = text
                textView.editable = false
                textView.selectable = false
                textView.textAlignment = .Center
                textView.font = .bold_Lar()
                textView.textColor = .whiteColor()
                textView.backgroundColor = .clearColor()
                scroll?.addSubview(textView)
            }
        }
        scroll?.contentSize = CGSizeMake(CGFloat(Int(screen.width) *  slides.count), screen.height * 0.5)
        scroll?.delegate = self
        dots?.addTarget(self, action: Selector("swipe:"), forControlEvents: UIControlEvents.ValueChanged)
        let closeButton = UIButton()
        closeButton.frame = CGRect(x: screen.width - 110, y: 10, width: 100, height: 40)
        closeButton.setTitle("Закрыть", forState: .Normal)
        closeButton.setTitleColor(.whiteColor(), forState: .Normal)
        closeButton.titleLabel!.font =  .bold_Med()
        closeButton.addTarget(self, action: "pressed:", forControlEvents: .TouchUpInside)
        view.addSubview(closeButton)
    }
    func pressed(sender: UIButton!) {
        dismissViewControllerAnimated(true) { [weak self] _ in
            self?.delegate?.onboardingDismissed()
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func getFrame (iW: CGFloat, iH: CGFloat, slide: Int, offset: CGFloat) -> CGRect {
        let mH: CGFloat = screen.height * 0.50
        let mW: CGFloat = screen.width
        var h: CGFloat
        var w: CGFloat
        let r = iW / iH
        if (r <= 1) {
            h = min(mH, iH)
            w = h * r
        } else {
            w = min(mW, iW)
            h = w / r
        }
        return CGRectMake(
            max(0, (mW - w) / 2) + CGFloat(slide) * screen.width,
            max(0, (mH - h) / 2) + offset,
            w,
            h
        )
    }
    func swipe(sender: AnyObject) -> () {
        if let scrollView = scroll {
            let x = CGFloat(dots!.currentPage) * scrollView.frame.size.width
            scroll?.setContentOffset(CGPointMake(x, 0), animated: true)
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) -> () {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        dots!.currentPage = Int(pageNumber)
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}