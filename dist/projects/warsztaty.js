const videos = document.querySelectorAll("video");
if (videos.length > 0)
  videos.forEach((video) => {
    video.play();
  });
