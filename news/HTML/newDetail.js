window.onload = function(){
    alert('感谢你的支持');

    var imageArray = document.getElementsByTagName("img");
    for(var i=0; i < imageArray.length; i++)
    {
        var image = imageArray[i];
        image.index = i;
        image.onclick = function(){

//        alert(imageArray[this.index].src);
            window.webkit.messageHandlers.openBigPicture.postMessage({methodName:"openBigPicture:",imageSrc:imageArray[this.index].src});
        }
    }


    var videoArray = document.getElementsByTagName("video");
    for(var i=0; i < videoArray.length; i++)
    {
        var myVideo = videoArray[i];

         function videoPlay(){
           window.webkit.messageHandlers.openVideoPlayer.postMessage({methodName:"openVideoPlayer:",videoSrc:myVideo.src});
            
        }

    }

    var videoDiv = document.getElementsByClassName("button01")[0];
    videoDiv.onclick = function(){
        videoPlay();
    }


    }
