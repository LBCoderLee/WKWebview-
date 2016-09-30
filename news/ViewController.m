//
//  ViewController.m
//  news
//
//  Created by li  bo on 16/9/22.
//  Copyright © 2016年 li  bo. All rights reserved.
//


/*下面就是网易新闻详情页返回内容的大致格式
 {
 "C1EIHLG905298O5P":{
 "body":"<!--IMG#0--><p>　　本文的........</p>",
 "users":Array[0],
 "img":[
 {
 "ref":"<!--IMG#0-->",
 "pixel":"750*300",
 "alt":"",
 "src":"http://dingyue.nosdn.127.net/Tr8iUc8j2n5PBgxr3omZKxNqu7IwGb2PzKGzhZ0b612fJ1474379598042compressflag.jpg"
 },
 ],
 "title":"NBA两亿先生跑不出这三位 除了威少哈登还有谁?",
 "ptime":"2016-09-20 21:56:57"
 }
 }
 */



#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "LBBigPictureViewController.h"
#import "LBVideoPlayerController.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>
/** 存放数据的字典 */
@property (nonatomic, strong) NSDictionary *htmlDict;

/** 浏览器 */
@property (nonatomic, strong) WKWebView *wkWebView;


/** 进度条 */
@property (nonatomic, strong) UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIView *contentView;


@end

@implementation ViewController



static NSString * const picMethodName = @"openBigPicture:";
static NSString * const videoMethodName = @"openVideoPlayer:";




- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, 1)];
    progressView.progress = 0.0;
    progressView.progressTintColor = [UIColor yellowColor];
    //progressView.trackTintColor = [UIColor redColor];


    [self.view addSubview:progressView];
    progressView.hidden = YES;
    self.progressView = progressView;

//    self.view.autoresizingMask= UIViewAutoresizingNone;
//    self.contentView.autoresizingMask = UIViewAutoresizingNone;
//    self.wkWebView.autoresizingMask = UIViewAutoresizingNone;


}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        self.wkWebView.autoresizingMask = UIViewAutoresizingNone;

    self.navigationItem.title= self.htmlDict[@"title"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //创建一个WKWebView的配置对象
    WKWebViewConfiguration *configur = [[WKWebViewConfiguration alloc] init];

    //设置configur对象的preferences属性的信息
    WKPreferences *preferences = [[WKPreferences alloc] init];
    configur.preferences = preferences;

    //是否允许与js进行交互，默认是YES的，如果设置为NO，js的代码就不起作用了
    preferences.javaScriptEnabled = YES;

    /*设置configur对象的WKUserContentController属性的信息，也就是设置js可与webview内容交互配置
     1、通过这个对象可以注入js名称，在js端通过window.webkit.messageHandlers.自定义的js名称.postMessage(如果有参数可以传递参数)方法来发送消息到native；
     2、我们需要遵守WKScriptMessageHandler协议，设置代理,然后实现对应代理方法(userContentController:didReceiveScriptMessage:);
     3、在上述代理方法里面就可以拿到对应的参数以及原生的方法名，我们就可以通过NSSelectorFromString包装成一个SEL，然后performSelector调用就可以了
     4、以上内容是WKWebview和UIWebview针对JS调用原生的方法最大的区别(UIWebview中主要是通过是否允许加载对应url的那个代理方法，通过在js代码里面写好特殊的url，然后拦截到对应的url，进行字符串的匹配以及截取操作，最后包装成SEL，然后调用就可以了)
     */

    /*
     上述是理论说明，结合下面的实际代码再做一次解释，保你一看就明白
     1、通过addScriptMessageHandler:name:方法，我们就可以注入js名称了,其实这个名称最好就是跟你的方法名一样，这样方便你包装使用，我这里自己写的就是openBigPicture，对应js中的代码就是window.webkit.messageHandlers.openBigPicture.postMessage()
     2、因为我的方法是有参数的，参数就是图片的url，因为点击网页中的图片，要调用原生的浏览大图的方法，所以你可以通过字符串拼接的方式给"openBigPicture"拼接成"openBigPicture:"，我这里没有采用这种方式，我传递的参数直接是字典，字典里面放了方法名以及图片的url，到时候直接取出来用就可以了
     3、我的js代码中关于这块的代码是
     window.webkit.messageHandlers.openBigPicture.postMessage({methodName:"openBigPicture:",imageSrc:imageArray[this.index].src});
     4、js和原生交互这块内容离不开
     - (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{}这个代理方法，这个方法以及参数说明请到下面方法对应处

     */
    WKUserContentController *userContentController = [[WKUserContentController alloc]init];
    [userContentController addScriptMessageHandler:self name:@"openBigPicture"];
    [userContentController addScriptMessageHandler:self name:@"openVideoPlayer"];
    configur.userContentController = userContentController;
    
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight) configuration:configur];

    //WKWebview的estimatedProgress属性，就是加载进度，它是支持KVO监听进度改变的
    [wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];

    [self.contentView addSubview:wkWebView];
    self.wkWebView = wkWebView;

    self.automaticallyAdjustsScrollViewInsets = NO;


    //设置内边距底部，主要是为了让网页最后的内容不被底部的toolBar挡着
    wkWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 104, 0);
    //这句代码是让竖直方向的滚动条显示在正确的位置
    wkWebView.scrollView.scrollIndicatorInsets = wkWebView.scrollView.contentInset;

    wkWebView.UIDelegate = self;
    
    self.wkWebView.navigationDelegate = self;

    [self getContentHtml];

    NSLog(@"%@",NSStringFromCGRect(self.wkWebView.frame));


    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{

    self.progressView.progress = self.wkWebView.estimatedProgress;
//    NSLog(@"%f", self.progressView.progress);

    //我这里之所以判断加载到大于60%，睡1s的原因是网速太快了，看不到进度条更新，所以停顿一下，主要是想明显看到进度条进度改变，没有其他意思的
    if (self.progressView.progress >0.6) {
        sleep(1);
    }
    //网页加载完毕隐藏进度条
    self.progressView.hidden = (self.wkWebView.estimatedProgress >= 1.0);

}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"estimatedProgress"];

}

//该方法作用就是创建一个网络请求任务去加载requst请求，然后把服务器返回的data数据进行反序列化处理，根据网易新闻返回的数据格式，实质就是一个字典

- (void)getContentHtml
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *requst = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://c.m.163.com/nc/article/C1EIHLG905298O5P/full.html"]];

        NSURLSessionDataTask *task = [session dataTaskWithRequest:requst completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {

           NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

            self.htmlDict = dict[@"C1EIHLG905298O5P"];

            //回到主线程刷新UI
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                self.navigationItem.title= self.htmlDict[@"title"];
            }];
            [self loadingHtmlNews];
        }
    }];
    //开启任务
    [task resume];

}

- (void)loadingHtmlNews
{
    //文章内容
    NSString *body = self.htmlDict[@"body"];

    //文章标题
    NSString *title = self.htmlDict[@"title"];
    //视频
    NSDictionary *videoDict = self.htmlDict[@"video"][0];
    NSString *videoUrl = videoDict[@"mp4_url"];
    NSString *alt = videoDict[@"alt"];
    NSString *videoRef = videoDict[@"ref"];
    NSString *videoHtml = [NSString stringWithFormat:@"<div>\
                           <video class=\"video0\" src=\"%@\" autoPlay=\"true\">\
                           </video>\
                           <div class=\"videoDescribe\">%@</div>\
                           </div>\
",videoUrl,alt];

    if (videoRef) {

        body = [body stringByReplacingOccurrencesOfString:videoRef withString:videoHtml];
    }

    //来源
    //来源01--网易号
    NSString *sourceName = [NSString string];
    if(self.htmlDict[@"articleTags"]){
        sourceName = self.htmlDict[@"articleTags"];
    }else {
        sourceName = self.htmlDict[@"source"];
    }
    //来源02--发布时间
    NSString *sourceTime = self.htmlDict[@"ptime"];
    //文章里面的图片
    NSArray *imagArray = self.htmlDict[@"img"];

    for (NSDictionary *imageDict in imagArray) {
        //图片在body中的占位标识，比如"<!--IMG#3-->"
        NSString *imageRef = imageDict[@"ref"];
        //图片的url
        NSString *imageSrc = imageDict[@"src"];
        //图片下面的文字说明
        NSString *imageAlt = imageDict[@"alt"];

        NSString *imageHtml  = [NSString string];

        //把对应的图片url转换成html里面显示图片的代码
        if (imageAlt) {

            imageHtml = [NSString stringWithFormat:@"<div><img width=\"100%%\" src=\"%@\"><div class=\"picDescribe\">%@</div></div>",imageSrc,imageAlt];
        }else{
            imageHtml = [NSString stringWithFormat:@"<div><img width=\"100%%\" src=\"%@\"></div>",imageSrc];
        }

        //这一步是显示图片的关键，主要就是把body里面的图片的占位标识给替换成上一步已经生成的html语法格式的图片代码，这样WKWebview加载html之后图片就可以被加载显示出来了
        body = [body stringByReplacingOccurrencesOfString:imageRef withString:imageHtml];
    }

    //css文件的全路径
    NSURL *cssPath = [[NSBundle mainBundle] URLForResource:@"newDetail" withExtension:@"css"];

//    NSURL *videoPath = [[NSBundle mainBundle] URLForResource:@"video-js" withExtension:@"css"];
    //js文件的路径
    NSURL *jsPath = [[NSBundle mainBundle] URLForResource:@"newDetail" withExtension:@"js"];


    //这里就是把前面的数据融入到html代码里面了，关于html的语法知识这里就不多说了，如果有不明白的可以咨询我或者亲自去w3c网站学习的-----“http://www.w3school.com.cn/”
    //OC中使用'\'就相当于说明了‘\’后面的内容和前面都是一起的

    NSString *html = [NSString stringWithFormat:@"\
                <html lang=\"en\">\
                      <head>\
                         <meta charset=\"UTF-8\">\
                         <link href=\"%@\" rel=\"stylesheet\">\
                      <link rel=\"stylesheet\" href=\"http://cdn.static.runoob.com/libs/bootstrap/3.3.7/css/bootstrap.min.css\">\
                         <script src=\"%@\"type=\"text/javascript\"></script>\
                      </head>\
                      <body id=\"mainBody\">\
                         <header>\
                      <div id=\"father\">\
                             <div id=\"mainTitle\">%@</div>\
                             <div id=\"sourceTitle\"><span class=\"source\">%@</span><span class=\"time\">%@</span></div>\
                                <video id=\"video1\" autoPlay=\"true\" src=\"http://flv2.bn.netease.com/videolib3/1609/24/VFTsu6784/HD/VFTsu6784-mobile.mp4\" controls=\"controls\">\
                                </video>\
                      <div class=\"button01 glyphicon glyphicon-play\"></div>\
                      <p class=\"lindan\">超级丹吊炸天</p>\
                             <div>%@</div>\
                      </div>\
                         </header>\
                      </body>\
                </html>"\
                      ,cssPath,jsPath,title,sourceName,sourceTime,body];


    //NSLog(@"%@",html);

   //这里需要说明一下，(loadHTMLString:baseURL:)这个方法的第二个参数，之前用UIWebview写的时候只需要传递nil即可正常加载本地css以及js文件，但是换成WKWebview之后你再传递nil，那么css以及js的代码就不会起任何作用，当时写的时候遇到了这个问题，谷歌了发现也有朋友遇到这个问题，但是还没有找到比较好的解决答案，后来自己又搜索了一下，从一个朋友的一句话中有了发现，就修改成了现在的正确代码，然后效果就可以正常显示了
    //使用现在这种写法之后，baseURL就指向了程序的资源路径，这样Html代码就和css以及js是一个路径的。不然WKWebview是无法加载的。当然baseURL也可以写一个网络路径，这样就可以用网络上的CSS了
  [self.wkWebView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];

}

#pragma mark - 刷新网页
- (IBAction)reload:(UIBarButtonItem *)sender {
    [self.wkWebView reload];
}

#pragma mark - WKScriptMessageHandler

/*
 1、js调用原生的方法就会走这个方法
 2、message参数里面有2个参数我们比较有用，name和body，
   2.1 :其中name就是之前已经通过addScriptMessageHandler:name:方法注入的js名称
   2.2 :其中body就是我们传递的参数了，我在js端传入的是一个字典，所以取出来也是字典，字典里面包含原生方法名以及被点击图片的url
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    //NSLog(@"%@,%@",message.name,message.body);

    NSDictionary *imageDict = message.body;
    NSString *src = [NSString string];
    if (imageDict[@"imageSrc"]) {
        src = imageDict[@"imageSrc"];
    }else{
        src = imageDict[@"videoSrc"];
    }
    NSString *name = imageDict[@"methodName"];

    //如果方法名是我们需要的，那么说明是时候调用原生对应的方法了
    if ([picMethodName isEqualToString:name]) {
        SEL sel = NSSelectorFromString(picMethodName);

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Warc-performSelector-leaks"
        //写在这个中间的代码,都不会被编译器提示PerformSelector may cause a leak because its selector is unknown类型的警告
        [self performSelector:sel withObject:src];
#pragma clang diagnostic pop
    }else if ([videoMethodName isEqualToString:name]){

        SEL sel = NSSelectorFromString(name);
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Warc-performSelector-leaks"

        [self performSelector:sel withObject:src];
#pragma clang diagnostic pop

    }
}

#pragma mark - WKUIDelegate(js弹框需要实现的代理方法)
//使用了WKWebView后，在JS端调用alert()是不会在HTML中显式弹出窗口，是我们需要在该方法中手动弹出iOS系统的alert的
//该方法中的message参数就是我们JS代码中alert函数里面的参数内容
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
//    NSLog(@"js弹框了");
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"JS-Coder" message:message preferredStyle:UIAlertControllerStyleAlert];

    [alertView addAction:[UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //一定要调用下这个block
        //API说明：The completion handler to call after the alert panel has been dismissed
        completionHandler();
    }]];
    [self presentViewController:alertView animated:YES completion:nil];

}


#pragma mark - JS调用 OC的方法进行图片浏览
- (void)openBigPicture:(NSString *)imageSrc
{
    //NSLog(@"%@",imageSrc);
    LBBigPictureViewController *picVc = [[LBBigPictureViewController alloc] init];
    picVc.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    picVc.imageSrc = imageSrc;

    [self presentViewController:picVc animated:YES completion:nil];

}


#pragma mark - JS调用 OC的方法进行视频播放
- (void)openVideoPlayer:(NSString *)videoSrc
{

    LBVideoPlayerController *videoPlayer = [[LBVideoPlayerController alloc] init];
    videoPlayer.videoSrc = videoSrc;

    [self presentViewController:videoPlayer animated:YES completion:nil];



}

@end
