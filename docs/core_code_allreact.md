Project Path: staroracle-app_allreact

Source Tree:

```txt
staroracle-app_allreact
├── capacitor.config.ts
├── index.html
├── ios
│   └── App
│       ├── App
│       │   ├── AppDelegate.swift
│       │   ├── Assets.xcassets
│       │   │   ├── AppIcon.appiconset
│       │   │   │   └── Contents.json
│       │   │   ├── Contents.json
│       │   │   └── Splash.imageset
│       │   │       └── Contents.json
│       │   ├── Base.lproj
│       │   │   ├── LaunchScreen.storyboard
│       │   │   └── Main.storyboard
│       │   └── Info.plist
│       ├── App.xcodeproj
│       │   ├── project.pbxproj
│       │   └── project.xcworkspace
│       │       ├── contents.xcworkspacedata
│       │       └── xcshareddata
│       │           └── swiftpm
│       │               └── configuration
│       ├── App.xcworkspace
│       │   ├── contents.xcworkspacedata
│       │   └── xcshareddata
│       │       ├── IDEWorkspaceChecks.plist
│       │       └── swiftpm
│       │           └── configuration
│       ├── Podfile
│       └── Podfile.lock
├── package.json
├── src
│   ├── App.tsx
│   ├── ErrorBoundary.tsx
│   ├── components
│   │   ├── AIConfigPanel.tsx
│   │   ├── AIMessage.tsx
│   │   ├── AwarenessDetailModal.tsx
│   │   ├── AwarenessIcon.tsx
│   │   ├── ChatMessages.tsx
│   │   ├── ChatOverlay.tsx
│   │   ├── CollectionButton.tsx
│   │   ├── Constellation.tsx
│   │   ├── ConstellationSelector.tsx
│   │   ├── ConversationDrawer.tsx
│   │   ├── DrawerMenu.tsx
│   │   ├── FloatingAwarenessPlanet.tsx
│   │   ├── Header.tsx
│   │   ├── InspirationCard.tsx
│   │   ├── LoadingMessage.tsx
│   │   ├── MessageContextMenu.tsx
│   │   ├── OracleInput.tsx
│   │   ├── Star.tsx
│   │   ├── StarCard.tsx
│   │   ├── StarCollection.tsx
│   │   ├── StarDetail.tsx
│   │   ├── StarLoadingAnimation.tsx
│   │   ├── StarRayIcon.tsx
│   │   ├── StarryBackground.tsx
│   │   ├── TemplateButton.tsx
│   │   └── UserMessage.tsx
│   ├── index.css
│   ├── main.tsx
│   ├── store
│   │   ├── useChatStore.ts
│   │   └── useStarStore.ts
│   ├── types
│   │   ├── chat.ts
│   │   └── index.ts
│   ├── utils
│   │   ├── aiTaggingUtils.ts
│   │   ├── bookOfAnswers.ts
│   │   ├── constellationTemplates.ts
│   │   ├── hapticUtils.ts
│   │   ├── imageUtils.ts
│   │   ├── inspirationCards.ts
│   │   ├── mobileUtils.ts
│   │   ├── oracleUtils.ts
│   │   └── soundUtils.ts
│   └── vite-env.d.ts
├── tailwind.config.js
├── tsconfig.app.json
├── tsconfig.json
├── tsconfig.node.json
└── vite.config.js

```

`staroracle-app_allreact/capacitor.config.ts`:

```ts
   1 | import type { CapacitorConfig } from '@capacitor/cli';
   2 | 
   3 | const config: CapacitorConfig = {
   4 |   appId: 'com.staroracle.app',
   5 |   appName: 'StarOracle',
   6 |   webDir: 'dist',
   7 |   server: {
   8 |     androidScheme: 'https'
   9 |   }
  10 | };
  11 | 
  12 | export default config;

```

`staroracle-app_allreact/index.html`:

```html
   1 | <!DOCTYPE html>
   2 | <html lang="zh-CN">
   3 |   <head>
   4 |     <meta charset="UTF-8">
   5 |     <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
   6 |     <title>星谕 - AI星座占卜</title>
   7 |     <meta name="description" content="基于AI的星座占卜应用，探索宇宙的奥秘">
   8 |     <meta name="keywords" content="星座, 占卜, AI, 星谕, 宇宙, 神秘学">
   9 | 
  10 |     <!-- 预加载字体 -->
  11 |     <link rel="preconnect" href="https://fonts.googleapis.com">
  12 |     <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="">
  13 |     <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@300;400;600&amp;family=Cormorant+Garamond:wght@300;400;500;600&amp;display=swap" rel="stylesheet">
  14 | 
  15 |     <!-- 图标 -->
  16 |     <link rel="icon" type="image/svg+xml" href="/star-icon.svg">
  17 | 
  18 |     <!-- 主题色彩 -->
  19 |     <meta name="theme-color" content="#8A5FBD">
  20 | 
  21 |     <!-- 移动端适配 -->
  22 |     <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  23 |     <meta name="apple-mobile-web-app-title" content="星谕">
  24 | 
  25 |     <!-- PWA支持 -->
  26 |     <meta name="application-name" content="星谕">
  27 |     <meta name="msapplication-TileColor" content="#8A5FBD">
  28 |     <style>
  29 |       /* 加载动画 */
  30 |       #loading-screen {
  31 |         position: fixed;
  32 |         top: 0;
  33 |         left: 0;
  34 |         width: 100%;
  35 |         height: 100%;
  36 |         background: linear-gradient(135deg, #090A0F 0%, #1B2735 100%);
  37 |         display: flex;
  38 |         flex-direction: column;
  39 |         align-items: center;
  40 |         justify-content: center;
  41 |         z-index: 9999;
  42 |         font-family: 'Cormorant Garamond', serif;
  43 |       }
  44 |       #loading-screen h1 {
  45 |         color: #8A5FBD;
  46 |         font-size: 2.5rem;
  47 |         margin-bottom: 2rem;
  48 |         font-weight: 600;
  49 |         letter-spacing: 0.1em;
  50 |       }
  51 |       .loading-spinner {
  52 |         width: 60px;
  53 |         height: 60px;
  54 |         border: 3px solid rgba(138, 95, 189, 0.3);
  55 |         border-top: 3px solid #8A5FBD;
  56 |         border-radius: 50%;
  57 |         animation: spin 1s linear infinite;
  58 |       }
  59 |       .loading-text {
  60 |         color: rgba(255, 255, 255, 0.7);
  61 |         margin-top: 1rem;
  62 |         font-size: 1rem;
  63 |         text-align: center;
  64 |       }
  65 |       @keyframes spin {
  66 |         0% {
  67 |           transform: rotate(0deg);
  68 |         }
  69 |         100% {
  70 |           transform: rotate(360deg);
  71 |         }
  72 |       }
  73 |       /* 隐藏加载屏幕的类 */
  74 |       .hide-loading {
  75 |         opacity: 0;
  76 |         visibility: hidden;
  77 |         transition: all 0.5s ease-out;
  78 |       }
  79 |     </style>
  80 |     <link rel="apple-touch-icon" href="ios/App/App/Assets.xcassets/apple-icon-180.png">
  81 |     <meta name="apple-mobile-web-app-capable" content="yes">
  82 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2048-2732.jpg" media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  83 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2732-2048.jpg" media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  84 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1668-2388.jpg" media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  85 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2388-1668.jpg" media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  86 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1536-2048.jpg" media="(device-width: 768px) and (device-height: 1024px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  87 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2048-1536.jpg" media="(device-width: 768px) and (device-height: 1024px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  88 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1640-2360.jpg" media="(device-width: 820px) and (device-height: 1180px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  89 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2360-1640.jpg" media="(device-width: 820px) and (device-height: 1180px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  90 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1668-2224.jpg" media="(device-width: 834px) and (device-height: 1112px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  91 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2224-1668.jpg" media="(device-width: 834px) and (device-height: 1112px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  92 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1620-2160.jpg" media="(device-width: 810px) and (device-height: 1080px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  93 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2160-1620.jpg" media="(device-width: 810px) and (device-height: 1080px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  94 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1488-2266.jpg" media="(device-width: 744px) and (device-height: 1133px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  95 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2266-1488.jpg" media="(device-width: 744px) and (device-height: 1133px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
  96 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1320-2868.jpg" media="(device-width: 440px) and (device-height: 956px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  97 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2868-1320.jpg" media="(device-width: 440px) and (device-height: 956px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
  98 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1206-2622.jpg" media="(device-width: 402px) and (device-height: 874px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  99 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2622-1206.jpg" media="(device-width: 402px) and (device-height: 874px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 100 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1290-2796.jpg" media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 101 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2796-1290.jpg" media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 102 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1179-2556.jpg" media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 103 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2556-1179.jpg" media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 104 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1170-2532.jpg" media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 105 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2532-1170.jpg" media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 106 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1284-2778.jpg" media="(device-width: 428px) and (device-height: 926px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 107 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2778-1284.jpg" media="(device-width: 428px) and (device-height: 926px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 108 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1125-2436.jpg" media="(device-width: 375px) and (device-height: 812px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 109 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2436-1125.jpg" media="(device-width: 375px) and (device-height: 812px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 110 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1242-2688.jpg" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 111 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2688-1242.jpg" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 112 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-828-1792.jpg" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
 113 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1792-828.jpg" media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
 114 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1242-2208.jpg" media="(device-width: 414px) and (device-height: 736px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
 115 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-2208-1242.jpg" media="(device-width: 414px) and (device-height: 736px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">
 116 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-750-1334.jpg" media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
 117 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1334-750.jpg" media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
 118 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-640-1136.jpg" media="(device-width: 320px) and (device-height: 568px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
 119 |     <link rel="apple-touch-startup-image" href="ios/App/App/Assets.xcassets/apple-splash-1136-640.jpg" media="(device-width: 320px) and (device-height: 568px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
 120 |   </head>
 121 |   <body>
 122 | 
 123 |     <!-- 加载屏幕 -->
 124 |     <div id="loading-screen">
 125 |       <h1>星谕</h1>
 126 |       <div class="loading-spinner"></div>
 127 |       <div class="loading-text">
 128 |         正在连接宇宙的奥秘...<br>
 129 |         <small>StarOracle is loading...</small>
 130 |       </div>
 131 |     </div>
 132 | 
 133 |     <!-- 应用根容器 -->
 134 |     <div id="root"></div>
 135 |     <script type="module" src="/src/main.tsx"></script>
 136 |     <script>
 137 |       // 检测是否为原生应用环境
 138 |       const isNativeApp = window.location.protocol === 'capacitor:' || 
 139 |                          window.navigator.userAgent.includes('CapacitorWebView');
 140 |       
 141 |       // 隐藏加载屏幕
 142 |       window.addEventListener('load', () => {
 143 |         // 如果是原生应用，快速隐藏 CSS 加载屏幕以避免双重加载
 144 |         const delay = isNativeApp ? 100 : 1000;
 145 |         
 146 |         setTimeout(() => {
 147 |           const loadingScreen = document.getElementById('loading-screen');
 148 |           if (loadingScreen) {
 149 |             loadingScreen.classList.add('hide-loading');
 150 |             setTimeout(() => {
 151 |               loadingScreen.remove();
 152 |             }, 500);
 153 |           }
 154 |         }, delay);
 155 |       });
 156 |       
 157 |       // 监听应用就绪事件
 158 |       window.addEventListener('app-ready', () => {
 159 |         const loadingScreen = document.getElementById('loading-screen');
 160 |         if (loadingScreen) {
 161 |           loadingScreen.classList.add('hide-loading');
 162 |           setTimeout(() => {
 163 |             loadingScreen.remove();
 164 |           }, 500);
 165 |         }
 166 |       });
 167 |     </script>
 168 |   </body>
 169 | </html>

```

`staroracle-app_allreact/ios/App/App.xcodeproj/project.pbxproj`:

```pbxproj
   1 | // !$*UTF8*$!
   2 | {
   3 | 	archiveVersion = 1;
   4 | 	classes = {
   5 | 	};
   6 | 	objectVersion = 48;
   7 | 	objects = {
   8 | 
   9 | /* Begin PBXBuildFile section */
  10 | 		2FAD9763203C412B000D30F8 /* config.xml in Resources */ = {isa = PBXBuildFile; fileRef = 2FAD9762203C412B000D30F8 /* config.xml */; };
  11 | 		50379B232058CBB4000EE86E /* capacitor.config.json in Resources */ = {isa = PBXBuildFile; fileRef = 50379B222058CBB4000EE86E /* capacitor.config.json */; };
  12 | 		504EC3081FED79650016851F /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 504EC3071FED79650016851F /* AppDelegate.swift */; };
  13 | 		504EC30D1FED79650016851F /* Main.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 504EC30B1FED79650016851F /* Main.storyboard */; };
  14 | 		504EC30F1FED79650016851F /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 504EC30E1FED79650016851F /* Assets.xcassets */; };
  15 | 		504EC3121FED79650016851F /* LaunchScreen.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 504EC3101FED79650016851F /* LaunchScreen.storyboard */; };
  16 | 		50B271D11FEDC1A000F3C39B /* public in Resources */ = {isa = PBXBuildFile; fileRef = 50B271D01FEDC1A000F3C39B /* public */; };
  17 | 		A084ECDBA7D38E1E42DFC39D /* Pods_App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = AF277DCFFFF123FFC6DF26C7 /* Pods_App.framework */; };
  18 | /* End PBXBuildFile section */
  19 | 
  20 | /* Begin PBXFileReference section */
  21 | 		2FAD9762203C412B000D30F8 /* config.xml */ = {isa = PBXFileReference; lastKnownFileType = text.xml; path = config.xml; sourceTree = "<group>"; };
  22 | 		50379B222058CBB4000EE86E /* capacitor.config.json */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.json; path = capacitor.config.json; sourceTree = "<group>"; };
  23 | 		504EC3041FED79650016851F /* App.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = App.app; sourceTree = BUILT_PRODUCTS_DIR; };
  24 | 		504EC3071FED79650016851F /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
  25 | 		504EC30C1FED79650016851F /* Base */ = {isa = PBXFileReference; lastKnownFileType = file.storyboard; name = Base; path = Base.lproj/Main.storyboard; sourceTree = "<group>"; };
  26 | 		504EC30E1FED79650016851F /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
  27 | 		504EC3111FED79650016851F /* Base */ = {isa = PBXFileReference; lastKnownFileType = file.storyboard; name = Base; path = Base.lproj/LaunchScreen.storyboard; sourceTree = "<group>"; };
  28 | 		504EC3131FED79650016851F /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
  29 | 		50B271D01FEDC1A000F3C39B /* public */ = {isa = PBXFileReference; lastKnownFileType = folder; path = public; sourceTree = "<group>"; };
  30 | 		AF277DCFFFF123FFC6DF26C7 /* Pods_App.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = Pods_App.framework; sourceTree = BUILT_PRODUCTS_DIR; };
  31 | 		AF51FD2D460BCFE21FA515B2 /* Pods-App.release.xcconfig */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.xcconfig; name = "Pods-App.release.xcconfig"; path = "Pods/Target Support Files/Pods-App/Pods-App.release.xcconfig"; sourceTree = "<group>"; };
  32 | 		FC68EB0AF532CFC21C3344DD /* Pods-App.debug.xcconfig */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.xcconfig; name = "Pods-App.debug.xcconfig"; path = "Pods/Target Support Files/Pods-App/Pods-App.debug.xcconfig"; sourceTree = "<group>"; };
  33 | /* End PBXFileReference section */
  34 | 
  35 | /* Begin PBXFrameworksBuildPhase section */
  36 | 		504EC3011FED79650016851F /* Frameworks */ = {
  37 | 			isa = PBXFrameworksBuildPhase;
  38 | 			buildActionMask = 2147483647;
  39 | 			files = (
  40 | 				A084ECDBA7D38E1E42DFC39D /* Pods_App.framework in Frameworks */,
  41 | 			);
  42 | 			runOnlyForDeploymentPostprocessing = 0;
  43 | 		};
  44 | /* End PBXFrameworksBuildPhase section */
  45 | 
  46 | /* Begin PBXGroup section */
  47 | 		27E2DDA53C4D2A4D1A88CE4A /* Frameworks */ = {
  48 | 			isa = PBXGroup;
  49 | 			children = (
  50 | 				AF277DCFFFF123FFC6DF26C7 /* Pods_App.framework */,
  51 | 			);
  52 | 			name = Frameworks;
  53 | 			sourceTree = "<group>";
  54 | 		};
  55 | 		504EC2FB1FED79650016851F = {
  56 | 			isa = PBXGroup;
  57 | 			children = (
  58 | 				504EC3061FED79650016851F /* App */,
  59 | 				504EC3051FED79650016851F /* Products */,
  60 | 				7F8756D8B27F46E3366F6CEA /* Pods */,
  61 | 				27E2DDA53C4D2A4D1A88CE4A /* Frameworks */,
  62 | 			);
  63 | 			sourceTree = "<group>";
  64 | 		};
  65 | 		504EC3051FED79650016851F /* Products */ = {
  66 | 			isa = PBXGroup;
  67 | 			children = (
  68 | 				504EC3041FED79650016851F /* App.app */,
  69 | 			);
  70 | 			name = Products;
  71 | 			sourceTree = "<group>";
  72 | 		};
  73 | 		504EC3061FED79650016851F /* App */ = {
  74 | 			isa = PBXGroup;
  75 | 			children = (
  76 | 				50379B222058CBB4000EE86E /* capacitor.config.json */,
  77 | 				504EC3071FED79650016851F /* AppDelegate.swift */,
  78 | 				504EC30B1FED79650016851F /* Main.storyboard */,
  79 | 				504EC30E1FED79650016851F /* Assets.xcassets */,
  80 | 				504EC3101FED79650016851F /* LaunchScreen.storyboard */,
  81 | 				504EC3131FED79650016851F /* Info.plist */,
  82 | 				2FAD9762203C412B000D30F8 /* config.xml */,
  83 | 				50B271D01FEDC1A000F3C39B /* public */,
  84 | 			);
  85 | 			path = App;
  86 | 			sourceTree = "<group>";
  87 | 		};
  88 | 		7F8756D8B27F46E3366F6CEA /* Pods */ = {
  89 | 			isa = PBXGroup;
  90 | 			children = (
  91 | 				FC68EB0AF532CFC21C3344DD /* Pods-App.debug.xcconfig */,
  92 | 				AF51FD2D460BCFE21FA515B2 /* Pods-App.release.xcconfig */,
  93 | 			);
  94 | 			name = Pods;
  95 | 			sourceTree = "<group>";
  96 | 		};
  97 | /* End PBXGroup section */
  98 | 
  99 | /* Begin PBXNativeTarget section */
 100 | 		504EC3031FED79650016851F /* App */ = {
 101 | 			isa = PBXNativeTarget;
 102 | 			buildConfigurationList = 504EC3161FED79650016851F /* Build configuration list for PBXNativeTarget "App" */;
 103 | 			buildPhases = (
 104 | 				6634F4EFEBD30273BCE97C65 /* [CP] Check Pods Manifest.lock */,
 105 | 				504EC3001FED79650016851F /* Sources */,
 106 | 				504EC3011FED79650016851F /* Frameworks */,
 107 | 				504EC3021FED79650016851F /* Resources */,
 108 | 				9592DBEFFC6D2A0C8D5DEB22 /* [CP] Embed Pods Frameworks */,
 109 | 			);
 110 | 			buildRules = (
 111 | 			);
 112 | 			dependencies = (
 113 | 			);
 114 | 			name = App;
 115 | 			productName = App;
 116 | 			productReference = 504EC3041FED79650016851F /* App.app */;
 117 | 			productType = "com.apple.product-type.application";
 118 | 		};
 119 | /* End PBXNativeTarget section */
 120 | 
 121 | /* Begin PBXProject section */
 122 | 		504EC2FC1FED79650016851F /* Project object */ = {
 123 | 			isa = PBXProject;
 124 | 			attributes = {
 125 | 				LastSwiftUpdateCheck = 0920;
 126 | 				LastUpgradeCheck = 0920;
 127 | 				TargetAttributes = {
 128 | 					504EC3031FED79650016851F = {
 129 | 						CreatedOnToolsVersion = 9.2;
 130 | 						LastSwiftMigration = 1100;
 131 | 						ProvisioningStyle = Automatic;
 132 | 					};
 133 | 				};
 134 | 			};
 135 | 			buildConfigurationList = 504EC2FF1FED79650016851F /* Build configuration list for PBXProject "App" */;
 136 | 			compatibilityVersion = "Xcode 8.0";
 137 | 			developmentRegion = en;
 138 | 			hasScannedForEncodings = 0;
 139 | 			knownRegions = (
 140 | 				en,
 141 | 				Base,
 142 | 			);
 143 | 			mainGroup = 504EC2FB1FED79650016851F;
 144 | 			packageReferences = (
 145 | 			);
 146 | 			productRefGroup = 504EC3051FED79650016851F /* Products */;
 147 | 			projectDirPath = "";
 148 | 			projectRoot = "";
 149 | 			targets = (
 150 | 				504EC3031FED79650016851F /* App */,
 151 | 			);
 152 | 		};
 153 | /* End PBXProject section */
 154 | 
 155 | /* Begin PBXResourcesBuildPhase section */
 156 | 		504EC3021FED79650016851F /* Resources */ = {
 157 | 			isa = PBXResourcesBuildPhase;
 158 | 			buildActionMask = 2147483647;
 159 | 			files = (
 160 | 				504EC3121FED79650016851F /* LaunchScreen.storyboard in Resources */,
 161 | 				50B271D11FEDC1A000F3C39B /* public in Resources */,
 162 | 				504EC30F1FED79650016851F /* Assets.xcassets in Resources */,
 163 | 				50379B232058CBB4000EE86E /* capacitor.config.json in Resources */,
 164 | 				504EC30D1FED79650016851F /* Main.storyboard in Resources */,
 165 | 				2FAD9763203C412B000D30F8 /* config.xml in Resources */,
 166 | 			);
 167 | 			runOnlyForDeploymentPostprocessing = 0;
 168 | 		};
 169 | /* End PBXResourcesBuildPhase section */
 170 | 
 171 | /* Begin PBXShellScriptBuildPhase section */
 172 | 		6634F4EFEBD30273BCE97C65 /* [CP] Check Pods Manifest.lock */ = {
 173 | 			isa = PBXShellScriptBuildPhase;
 174 | 			buildActionMask = 2147483647;
 175 | 			files = (
 176 | 			);
 177 | 			inputPaths = (
 178 | 				"${PODS_PODFILE_DIR_PATH}/Podfile.lock",
 179 | 				"${PODS_ROOT}/Manifest.lock",
 180 | 			);
 181 | 			name = "[CP] Check Pods Manifest.lock";
 182 | 			outputPaths = (
 183 | 				"$(DERIVED_FILE_DIR)/Pods-App-checkManifestLockResult.txt",
 184 | 			);
 185 | 			runOnlyForDeploymentPostprocessing = 0;
 186 | 			shellPath = /bin/sh;
 187 | 			shellScript = "diff \"${PODS_PODFILE_DIR_PATH}/Podfile.lock\" \"${PODS_ROOT}/Manifest.lock\" > /dev/null\nif [ $? != 0 ] ; then\n    # print error to STDERR\n    echo \"error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation.\" >&2\n    exit 1\nfi\n# This output is used by Xcode 'outputs' to avoid re-running this script phase.\necho \"SUCCESS\" > \"${SCRIPT_OUTPUT_FILE_0}\"\n";
 188 | 			showEnvVarsInLog = 0;
 189 | 		};
 190 | 		9592DBEFFC6D2A0C8D5DEB22 /* [CP] Embed Pods Frameworks */ = {
 191 | 			isa = PBXShellScriptBuildPhase;
 192 | 			buildActionMask = 2147483647;
 193 | 			files = (
 194 | 			);
 195 | 			inputPaths = (
 196 | 			);
 197 | 			name = "[CP] Embed Pods Frameworks";
 198 | 			outputPaths = (
 199 | 			);
 200 | 			runOnlyForDeploymentPostprocessing = 0;
 201 | 			shellPath = /bin/sh;
 202 | 			shellScript = "\"${PODS_ROOT}/Target Support Files/Pods-App/Pods-App-frameworks.sh\"\n";
 203 | 			showEnvVarsInLog = 0;
 204 | 		};
 205 | /* End PBXShellScriptBuildPhase section */
 206 | 
 207 | /* Begin PBXSourcesBuildPhase section */
 208 | 		504EC3001FED79650016851F /* Sources */ = {
 209 | 			isa = PBXSourcesBuildPhase;
 210 | 			buildActionMask = 2147483647;
 211 | 			files = (
 212 | 				504EC3081FED79650016851F /* AppDelegate.swift in Sources */,
 213 | 			);
 214 | 			runOnlyForDeploymentPostprocessing = 0;
 215 | 		};
 216 | /* End PBXSourcesBuildPhase section */
 217 | 
 218 | /* Begin PBXVariantGroup section */
 219 | 		504EC30B1FED79650016851F /* Main.storyboard */ = {
 220 | 			isa = PBXVariantGroup;
 221 | 			children = (
 222 | 				504EC30C1FED79650016851F /* Base */,
 223 | 			);
 224 | 			name = Main.storyboard;
 225 | 			sourceTree = "<group>";
 226 | 		};
 227 | 		504EC3101FED79650016851F /* LaunchScreen.storyboard */ = {
 228 | 			isa = PBXVariantGroup;
 229 | 			children = (
 230 | 				504EC3111FED79650016851F /* Base */,
 231 | 			);
 232 | 			name = LaunchScreen.storyboard;
 233 | 			sourceTree = "<group>";
 234 | 		};
 235 | /* End PBXVariantGroup section */
 236 | 
 237 | /* Begin XCBuildConfiguration section */
 238 | 		504EC3141FED79650016851F /* Debug */ = {
 239 | 			isa = XCBuildConfiguration;
 240 | 			buildSettings = {
 241 | 				ALWAYS_SEARCH_USER_PATHS = NO;
 242 | 				CLANG_ANALYZER_NONNULL = YES;
 243 | 				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
 244 | 				CLANG_CXX_LANGUAGE_STANDARD = "gnu++14";
 245 | 				CLANG_CXX_LIBRARY = "libc++";
 246 | 				CLANG_ENABLE_MODULES = YES;
 247 | 				CLANG_ENABLE_OBJC_ARC = YES;
 248 | 				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
 249 | 				CLANG_WARN_BOOL_CONVERSION = YES;
 250 | 				CLANG_WARN_COMMA = YES;
 251 | 				CLANG_WARN_CONSTANT_CONVERSION = YES;
 252 | 				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
 253 | 				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
 254 | 				CLANG_WARN_EMPTY_BODY = YES;
 255 | 				CLANG_WARN_ENUM_CONVERSION = YES;
 256 | 				CLANG_WARN_INFINITE_RECURSION = YES;
 257 | 				CLANG_WARN_INT_CONVERSION = YES;
 258 | 				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
 259 | 				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
 260 | 				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
 261 | 				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
 262 | 				CLANG_WARN_STRICT_PROTOTYPES = YES;
 263 | 				CLANG_WARN_SUSPICIOUS_MOVE = YES;
 264 | 				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
 265 | 				CLANG_WARN_UNREACHABLE_CODE = YES;
 266 | 				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
 267 | 				CODE_SIGN_IDENTITY = "iPhone Developer";
 268 | 				COPY_PHASE_STRIP = NO;
 269 | 				DEBUG_INFORMATION_FORMAT = dwarf;
 270 | 				ENABLE_STRICT_OBJC_MSGSEND = YES;
 271 | 				ENABLE_TESTABILITY = YES;
 272 | 				GCC_C_LANGUAGE_STANDARD = gnu11;
 273 | 				GCC_DYNAMIC_NO_PIC = NO;
 274 | 				GCC_NO_COMMON_BLOCKS = YES;
 275 | 				GCC_OPTIMIZATION_LEVEL = 0;
 276 | 				GCC_PREPROCESSOR_DEFINITIONS = (
 277 | 					"DEBUG=1",
 278 | 					"$(inherited)",
 279 | 				);
 280 | 				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
 281 | 				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
 282 | 				GCC_WARN_UNDECLARED_SELECTOR = YES;
 283 | 				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
 284 | 				GCC_WARN_UNUSED_FUNCTION = YES;
 285 | 				GCC_WARN_UNUSED_VARIABLE = YES;
 286 | 				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
 287 | 				MTL_ENABLE_DEBUG_INFO = YES;
 288 | 				ONLY_ACTIVE_ARCH = YES;
 289 | 				SDKROOT = iphoneos;
 290 | 				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
 291 | 				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
 292 | 			};
 293 | 			name = Debug;
 294 | 		};
 295 | 		504EC3151FED79650016851F /* Release */ = {
 296 | 			isa = XCBuildConfiguration;
 297 | 			buildSettings = {
 298 | 				ALWAYS_SEARCH_USER_PATHS = NO;
 299 | 				CLANG_ANALYZER_NONNULL = YES;
 300 | 				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
 301 | 				CLANG_CXX_LANGUAGE_STANDARD = "gnu++14";
 302 | 				CLANG_CXX_LIBRARY = "libc++";
 303 | 				CLANG_ENABLE_MODULES = YES;
 304 | 				CLANG_ENABLE_OBJC_ARC = YES;
 305 | 				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
 306 | 				CLANG_WARN_BOOL_CONVERSION = YES;
 307 | 				CLANG_WARN_COMMA = YES;
 308 | 				CLANG_WARN_CONSTANT_CONVERSION = YES;
 309 | 				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
 310 | 				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
 311 | 				CLANG_WARN_EMPTY_BODY = YES;
 312 | 				CLANG_WARN_ENUM_CONVERSION = YES;
 313 | 				CLANG_WARN_INFINITE_RECURSION = YES;
 314 | 				CLANG_WARN_INT_CONVERSION = YES;
 315 | 				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
 316 | 				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
 317 | 				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
 318 | 				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
 319 | 				CLANG_WARN_STRICT_PROTOTYPES = YES;
 320 | 				CLANG_WARN_SUSPICIOUS_MOVE = YES;
 321 | 				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
 322 | 				CLANG_WARN_UNREACHABLE_CODE = YES;
 323 | 				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
 324 | 				CODE_SIGN_IDENTITY = "iPhone Developer";
 325 | 				COPY_PHASE_STRIP = NO;
 326 | 				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
 327 | 				ENABLE_NS_ASSERTIONS = NO;
 328 | 				ENABLE_STRICT_OBJC_MSGSEND = YES;
 329 | 				GCC_C_LANGUAGE_STANDARD = gnu11;
 330 | 				GCC_NO_COMMON_BLOCKS = YES;
 331 | 				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
 332 | 				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
 333 | 				GCC_WARN_UNDECLARED_SELECTOR = YES;
 334 | 				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
 335 | 				GCC_WARN_UNUSED_FUNCTION = YES;
 336 | 				GCC_WARN_UNUSED_VARIABLE = YES;
 337 | 				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
 338 | 				MTL_ENABLE_DEBUG_INFO = NO;
 339 | 				SDKROOT = iphoneos;
 340 | 				SWIFT_OPTIMIZATION_LEVEL = "-Owholemodule";
 341 | 				VALIDATE_PRODUCT = YES;
 342 | 			};
 343 | 			name = Release;
 344 | 		};
 345 | 		504EC3171FED79650016851F /* Debug */ = {
 346 | 			isa = XCBuildConfiguration;
 347 | 			baseConfigurationReference = FC68EB0AF532CFC21C3344DD /* Pods-App.debug.xcconfig */;
 348 | 			buildSettings = {
 349 | 				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
 350 | 				CODE_SIGN_STYLE = Automatic;
 351 | 				CURRENT_PROJECT_VERSION = 1;
 352 | 				DEVELOPMENT_TEAM = GDMNN32LF4;
 353 | 				INFOPLIST_FILE = App/Info.plist;
 354 | 				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
 355 | 				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
 356 | 				MARKETING_VERSION = 1.0;
 357 | 				OTHER_SWIFT_FLAGS = "$(inherited) \"-D\" \"COCOAPODS\" \"-DDEBUG\"";
 358 | 				PRODUCT_BUNDLE_IDENTIFIER = com.staroracle.app;
 359 | 				PRODUCT_NAME = "$(TARGET_NAME)";
 360 | 				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
 361 | 				SWIFT_VERSION = 5.0;
 362 | 				TARGETED_DEVICE_FAMILY = "1,2";
 363 | 			};
 364 | 			name = Debug;
 365 | 		};
 366 | 		504EC3181FED79650016851F /* Release */ = {
 367 | 			isa = XCBuildConfiguration;
 368 | 			baseConfigurationReference = AF51FD2D460BCFE21FA515B2 /* Pods-App.release.xcconfig */;
 369 | 			buildSettings = {
 370 | 				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
 371 | 				CODE_SIGN_STYLE = Automatic;
 372 | 				CURRENT_PROJECT_VERSION = 1;
 373 | 				DEVELOPMENT_TEAM = GDMNN32LF4;
 374 | 				INFOPLIST_FILE = App/Info.plist;
 375 | 				IPHONEOS_DEPLOYMENT_TARGET = 14.0;
 376 | 				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
 377 | 				MARKETING_VERSION = 1.0;
 378 | 				PRODUCT_BUNDLE_IDENTIFIER = com.staroracle.app;
 379 | 				PRODUCT_NAME = "$(TARGET_NAME)";
 380 | 				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "";
 381 | 				SWIFT_VERSION = 5.0;
 382 | 				TARGETED_DEVICE_FAMILY = "1,2";
 383 | 			};
 384 | 			name = Release;
 385 | 		};
 386 | /* End XCBuildConfiguration section */
 387 | 
 388 | /* Begin XCConfigurationList section */
 389 | 		504EC2FF1FED79650016851F /* Build configuration list for PBXProject "App" */ = {
 390 | 			isa = XCConfigurationList;
 391 | 			buildConfigurations = (
 392 | 				504EC3141FED79650016851F /* Debug */,
 393 | 				504EC3151FED79650016851F /* Release */,
 394 | 			);
 395 | 			defaultConfigurationIsVisible = 0;
 396 | 			defaultConfigurationName = Release;
 397 | 		};
 398 | 		504EC3161FED79650016851F /* Build configuration list for PBXNativeTarget "App" */ = {
 399 | 			isa = XCConfigurationList;
 400 | 			buildConfigurations = (
 401 | 				504EC3171FED79650016851F /* Debug */,
 402 | 				504EC3181FED79650016851F /* Release */,
 403 | 			);
 404 | 			defaultConfigurationIsVisible = 0;
 405 | 			defaultConfigurationName = Release;
 406 | 		};
 407 | /* End XCConfigurationList section */
 408 | 	};
 409 | 	rootObject = 504EC2FC1FED79650016851F /* Project object */;
 410 | }

```

`staroracle-app_allreact/ios/App/App.xcodeproj/project.xcworkspace/contents.xcworkspacedata`:

```xcworkspacedata
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <Workspace
   3 |    version = "1.0">
   4 |    <FileRef
   5 |       location = "self:">
   6 |    </FileRef>
   7 | </Workspace>

```

`staroracle-app_allreact/ios/App/App.xcworkspace/contents.xcworkspacedata`:

```xcworkspacedata
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <Workspace
   3 |    version = "1.0">
   4 |    <FileRef
   5 |       location = "group:App.xcodeproj">
   6 |    </FileRef>
   7 |    <FileRef
   8 |       location = "group:Pods/Pods.xcodeproj">
   9 |    </FileRef>
  10 | </Workspace>

```

`staroracle-app_allreact/ios/App/App.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`:

```plist
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   3 | <plist version="1.0">
   4 | <dict>
   5 | 	<key>IDEDidComputeMac32BitWarning</key>
   6 | 	<true/>
   7 | </dict>
   8 | </plist>

```

`staroracle-app_allreact/ios/App/App/AppDelegate.swift`:

```swift
   1 | import UIKit
   2 | import Capacitor
   3 | 
   4 | @UIApplicationMain
   5 | class AppDelegate: UIResponder, UIApplicationDelegate {
   6 | 
   7 |     var window: UIWindow?
   8 | 
   9 |     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  10 |         // Override point for customization after application launch.
  11 |         return true
  12 |     }
  13 | 
  14 |     func applicationWillResignActive(_ application: UIApplication) {
  15 |         // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  16 |         // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  17 |     }
  18 | 
  19 |     func applicationDidEnterBackground(_ application: UIApplication) {
  20 |         // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  21 |         // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  22 |     }
  23 | 
  24 |     func applicationWillEnterForeground(_ application: UIApplication) {
  25 |         // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  26 |     }
  27 | 
  28 |     func applicationDidBecomeActive(_ application: UIApplication) {
  29 |         // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  30 |     }
  31 | 
  32 |     func applicationWillTerminate(_ application: UIApplication) {
  33 |         // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  34 |     }
  35 | 
  36 |     func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
  37 |         // Called when the app was launched with a url. Feel free to add additional processing here,
  38 |         // but if you want the App API to support tracking app url opens, make sure to keep this call
  39 |         return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
  40 |     }
  41 | 
  42 |     func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
  43 |         // Called when the app was launched with an activity, including Universal Links.
  44 |         // Feel free to add additional processing here, but if you want the App API to support
  45 |         // tracking app url opens, make sure to keep this call
  46 |         return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
  47 |     }
  48 | 
  49 | }

```

`staroracle-app_allreact/ios/App/App/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
   1 | {
   2 |   "images" : [
   3 |     {
   4 |       "filename" : "AppIcon-512@2x.png",
   5 |       "idiom" : "universal",
   6 |       "platform" : "ios",
   7 |       "size" : "1024x1024"
   8 |     }
   9 |   ],
  10 |   "info" : {
  11 |     "author" : "xcode",
  12 |     "version" : 1
  13 |   }
  14 | }

```

`staroracle-app_allreact/ios/App/App/Assets.xcassets/Contents.json`:

```json
   1 | {
   2 |   "info" : {
   3 |     "version" : 1,
   4 |     "author" : "xcode"
   5 |   }
   6 | }

```

`staroracle-app_allreact/ios/App/App/Assets.xcassets/Splash.imageset/Contents.json`:

```json
   1 | {
   2 |   "images" : [
   3 |     {
   4 |       "idiom" : "universal",
   5 |       "filename" : "splash-2732x2732-2.png",
   6 |       "scale" : "1x"
   7 |     },
   8 |     {
   9 |       "idiom" : "universal",
  10 |       "filename" : "splash-2732x2732-1.png",
  11 |       "scale" : "2x"
  12 |     },
  13 |     {
  14 |       "idiom" : "universal",
  15 |       "filename" : "splash-2732x2732.png",
  16 |       "scale" : "3x"
  17 |     }
  18 |   ],
  19 |   "info" : {
  20 |     "version" : 1,
  21 |     "author" : "xcode"
  22 |   }
  23 | }

```

`staroracle-app_allreact/ios/App/App/Base.lproj/LaunchScreen.storyboard`:

```storyboard
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="17132" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
   3 |     <device id="retina4_7" orientation="portrait" appearance="light"/>
   4 |     <dependencies>
   5 |         <deployment identifier="iOS"/>
   6 |         <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="17105"/>
   7 |         <capability name="System colors in document resources" minToolsVersion="11.0"/>
   8 |         <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
   9 |     </dependencies>
  10 |     <scenes>
  11 |         <!--View Controller-->
  12 |         <scene sceneID="EHf-IW-A2E">
  13 |             <objects>
  14 |                 <viewController id="01J-lp-oVM" sceneMemberID="viewController">
  15 |                     <imageView key="view" userInteractionEnabled="NO" contentMode="scaleAspectFill" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="Splash" id="snD-IY-ifK">
  16 |                         <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
  17 |                         <autoresizingMask key="autoresizingMask"/>
  18 |                         <color key="backgroundColor" systemColor="systemBackgroundColor"/>
  19 |                     </imageView>
  20 |                 </viewController>
  21 |                 <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
  22 |             </objects>
  23 |             <point key="canvasLocation" x="53" y="375"/>
  24 |         </scene>
  25 |     </scenes>
  26 |     <resources>
  27 |         <image name="Splash" width="1366" height="1366"/>
  28 |         <systemColor name="systemBackgroundColor">
  29 |             <color white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
  30 |         </systemColor>
  31 |     </resources>
  32 | </document>

```

`staroracle-app_allreact/ios/App/App/Base.lproj/Main.storyboard`:

```storyboard
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="14111" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" colorMatched="YES" initialViewController="BYZ-38-t0r">
   3 |     <device id="retina4_7" orientation="portrait">
   4 |         <adaptation id="fullscreen"/>
   5 |     </device>
   6 |     <dependencies>
   7 |         <deployment identifier="iOS"/>
   8 |         <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="14088"/>
   9 |     </dependencies>
  10 |     <scenes>
  11 |         <!--Bridge View Controller-->
  12 |         <scene sceneID="tne-QT-ifu">
  13 |             <objects>
  14 |                 <viewController id="BYZ-38-t0r" customClass="CAPBridgeViewController" customModule="Capacitor" sceneMemberID="viewController"/>
  15 |                 <placeholder placeholderIdentifier="IBFirstResponder" id="dkx-z0-nzr" sceneMemberID="firstResponder"/>
  16 |             </objects>
  17 |         </scene>
  18 |     </scenes>
  19 | </document>

```

`staroracle-app_allreact/ios/App/App/Info.plist`:

```plist
   1 | <?xml version="1.0" encoding="UTF-8"?>
   2 | <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   3 | <plist version="1.0">
   4 | <dict>
   5 | 	<key>CFBundleDevelopmentRegion</key>
   6 | 	<string>en</string>
   7 | 	<key>CFBundleDisplayName</key>
   8 |         <string>StarOracle</string>
   9 | 	<key>CFBundleExecutable</key>
  10 | 	<string>$(EXECUTABLE_NAME)</string>
  11 | 	<key>CFBundleIdentifier</key>
  12 | 	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  13 | 	<key>CFBundleInfoDictionaryVersion</key>
  14 | 	<string>6.0</string>
  15 | 	<key>CFBundleName</key>
  16 | 	<string>$(PRODUCT_NAME)</string>
  17 | 	<key>CFBundlePackageType</key>
  18 | 	<string>APPL</string>
  19 | 	<key>CFBundleShortVersionString</key>
  20 | 	<string>$(MARKETING_VERSION)</string>
  21 | 	<key>CFBundleVersion</key>
  22 | 	<string>$(CURRENT_PROJECT_VERSION)</string>
  23 | 	<key>LSRequiresIPhoneOS</key>
  24 | 	<true/>
  25 | 	<key>UILaunchStoryboardName</key>
  26 | 	<string>LaunchScreen</string>
  27 | 	<key>UIMainStoryboardFile</key>
  28 | 	<string>Main</string>
  29 | 	<key>UIRequiredDeviceCapabilities</key>
  30 | 	<array>
  31 | 		<string>armv7</string>
  32 | 	</array>
  33 | 	<key>UISupportedInterfaceOrientations</key>
  34 | 	<array>
  35 | 		<string>UIInterfaceOrientationPortrait</string>
  36 | 		<string>UIInterfaceOrientationLandscapeLeft</string>
  37 | 		<string>UIInterfaceOrientationLandscapeRight</string>
  38 | 	</array>
  39 | 	<key>UISupportedInterfaceOrientations~ipad</key>
  40 | 	<array>
  41 | 		<string>UIInterfaceOrientationPortrait</string>
  42 | 		<string>UIInterfaceOrientationPortraitUpsideDown</string>
  43 | 		<string>UIInterfaceOrientationLandscapeLeft</string>
  44 | 		<string>UIInterfaceOrientationLandscapeRight</string>
  45 | 	</array>
  46 | 	<key>UIViewControllerBasedStatusBarAppearance</key>
  47 | 	<true/>
  48 | </dict>
  49 | </plist>

```

`staroracle-app_allreact/ios/App/Podfile`:

```
   1 | require_relative '../../node_modules/@capacitor/ios/scripts/pods_helpers'
   2 | 
   3 | platform :ios, '14.0'
   4 | use_frameworks!
   5 | 
   6 | # workaround to avoid Xcode caching of Pods that requires
   7 | # Product -> Clean Build Folder after new Cordova plugins installed
   8 | # Requires CocoaPods 1.6 or newer
   9 | install! 'cocoapods', :disable_input_output_paths => true
  10 | 
  11 | def capacitor_pods
  12 |   pod 'Capacitor', :path => '../../node_modules/@capacitor/ios'
  13 |   pod 'CapacitorCordova', :path => '../../node_modules/@capacitor/ios'
  14 |   pod 'CapacitorHaptics', :path => '../../node_modules/@capacitor/haptics'
  15 |   pod 'CapacitorKeyboard', :path => '../../node_modules/@capacitor/keyboard'
  16 |   pod 'CapacitorSplashScreen', :path => '../../node_modules/@capacitor/splash-screen'
  17 |   pod 'CapacitorStatusBar', :path => '../../node_modules/@capacitor/status-bar'
  18 | end
  19 | 
  20 | target 'App' do
  21 |   capacitor_pods
  22 |   # Add your Pods here
  23 | end
  24 | 
  25 | post_install do |installer|
  26 |   assertDeploymentTarget(installer)
  27 | end

```

`staroracle-app_allreact/ios/App/Podfile.lock`:

```lock
   1 | PODS:
   2 |   - Capacitor (7.4.2):
   3 |     - CapacitorCordova
   4 |   - CapacitorCordova (7.4.2)
   5 |   - CapacitorHaptics (7.0.2):
   6 |     - Capacitor
   7 |   - CapacitorKeyboard (7.0.2):
   8 |     - Capacitor
   9 |   - CapacitorSplashScreen (7.0.2):
  10 |     - Capacitor
  11 |   - CapacitorStatusBar (7.0.2):
  12 |     - Capacitor
  13 | 
  14 | DEPENDENCIES:
  15 |   - "Capacitor (from `../../node_modules/@capacitor/ios`)"
  16 |   - "CapacitorCordova (from `../../node_modules/@capacitor/ios`)"
  17 |   - "CapacitorHaptics (from `../../node_modules/@capacitor/haptics`)"
  18 |   - "CapacitorKeyboard (from `../../node_modules/@capacitor/keyboard`)"
  19 |   - "CapacitorSplashScreen (from `../../node_modules/@capacitor/splash-screen`)"
  20 |   - "CapacitorStatusBar (from `../../node_modules/@capacitor/status-bar`)"
  21 | 
  22 | EXTERNAL SOURCES:
  23 |   Capacitor:
  24 |     :path: "../../node_modules/@capacitor/ios"
  25 |   CapacitorCordova:
  26 |     :path: "../../node_modules/@capacitor/ios"
  27 |   CapacitorHaptics:
  28 |     :path: "../../node_modules/@capacitor/haptics"
  29 |   CapacitorKeyboard:
  30 |     :path: "../../node_modules/@capacitor/keyboard"
  31 |   CapacitorSplashScreen:
  32 |     :path: "../../node_modules/@capacitor/splash-screen"
  33 |   CapacitorStatusBar:
  34 |     :path: "../../node_modules/@capacitor/status-bar"
  35 | 
  36 | SPEC CHECKSUMS:
  37 |   Capacitor: 9d9e481b79ffaeacaf7a85d6a11adec32bd33b59
  38 |   CapacitorCordova: 5e58d04631bc5094894ac106e2bf1da18a9e6151
  39 |   CapacitorHaptics: b3fb2869e72c4466e18ce9ccbeb60a3d8723b3d4
  40 |   CapacitorKeyboard: a86aa9e4741b6444a802df26440a92ae041b34a6
  41 |   CapacitorSplashScreen: 157947576b59d913792063a8d442a79e6d283ee5
  42 |   CapacitorStatusBar: e04d05e121d5a5979c29eb4249186a4e4a84cacb
  43 | 
  44 | PODFILE CHECKSUM: 522eb1efdcf41619219905b4ae4996a81f937984
  45 | 
  46 | COCOAPODS: 1.16.2

```

`staroracle-app_allreact/package.json`:

```json
   1 | {
   2 |   "name": "star-oracle-app",
   3 |   "version": "1.0.0",
   4 |   "private": true,
   5 |   "type": "module",
   6 |   "scripts": {
   7 |     "dev": "vite",
   8 |     "build": "tsc && vite build",
   9 |     "preview": "vite preview"
  10 |   },
  11 |   "dependencies": {
  12 |     "@capacitor/android": "^7.4.2",
  13 |     "@capacitor/core": "^7.4.2",
  14 |     "@capacitor/haptics": "^7.0.2",
  15 |     "@capacitor/ios": "^7.4.2",
  16 |     "@capacitor/keyboard": "^7.0.2",
  17 |     "@capacitor/splash-screen": "^7.0.2",
  18 |     "@capacitor/status-bar": "^7.0.2",
  19 |     "framer-motion": "^11.0.8",
  20 |     "howler": "^2.2.4",
  21 |     "lucide-react": "^0.372.0",
  22 |     "react": "^18.2.0",
  23 |     "react-dom": "^18.2.0",
  24 |     "zustand": "^4.5.2"
  25 |   },
  26 |   "devDependencies": {
  27 |     "@capacitor/cli": "^7.4.2",
  28 |     "@types/howler": "^2.2.11",
  29 |     "@types/react": "^18.2.79",
  30 |     "@types/react-dom": "^18.2.25",
  31 |     "@vitejs/plugin-react": "^4.2.1",
  32 |     "autoprefixer": "^10.4.21",
  33 |     "postcss": "^8.5.6",
  34 |     "tailwindcss": "^3.4.1",
  35 |     "typescript": "^5.4.5",
  36 |     "vite": "^5.2.10"
  37 |   }
  38 | }

```

`staroracle-app_allreact/src/App.tsx`:

```tsx
   1 | import React, { useEffect, useState } from 'react';
   2 | import { Capacitor } from '@capacitor/core';
   3 | import { StatusBar, Style } from '@capacitor/status-bar';
   4 | import { SplashScreen } from '@capacitor/splash-screen';
   5 | import { Keyboard } from '@capacitor/keyboard';
   6 | import StarryBackground from './components/StarryBackground';
   7 | import Constellation from './components/Constellation';
   8 | import ChatMessages from './components/ChatMessages';
   9 | import InspirationCard from './components/InspirationCard';
  10 | import StarDetail from './components/StarDetail';
  11 | import StarCollection from './components/StarCollection';
  12 | import ConstellationSelector from './components/ConstellationSelector';
  13 | import AIConfigPanel from './components/AIConfigPanel';
  14 | import DrawerMenu from './components/DrawerMenu';
  15 | import Header from './components/Header';
  16 | import ConversationDrawer from './components/ConversationDrawer';
  17 | import ChatOverlay from './components/ChatOverlay'; // 新增对话浮层
  18 | import OracleInput from './components/OracleInput';
  19 | import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
  20 | import { triggerHapticFeedback } from './utils/hapticUtils';
  21 | import { Menu } from 'lucide-react';
  22 | import { useStarStore } from './store/useStarStore';
  23 | import { useChatStore } from './store/useChatStore';
  24 | import { ConstellationTemplate } from './types';
  25 | import { checkApiConfiguration } from './utils/aiTaggingUtils';
  26 | import { motion, AnimatePresence } from 'framer-motion';
  27 | 
  28 | function App() {
  29 |   const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  30 |   const [isConfigOpen, setIsConfigOpen] = useState(false);
  31 |   const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  32 |   const [isDrawerMenuOpen, setIsDrawerMenuOpen] = useState(false);
  33 |   const [appReady, setAppReady] = useState(false);
  34 |   const [pendingFollowUpQuestion, setPendingFollowUpQuestion] = useState<string>(''); // 待处理的后续问题
  35 |   const [isChatOverlayOpen, setIsChatOverlayOpen] = useState(false); // 新增对话浮层状态
  36 |   const [initialChatInput, setInitialChatInput] = useState<string>(''); // 初始输入内容
  37 |   
  38 |   const { 
  39 |     applyTemplate, 
  40 |     currentInspirationCard, 
  41 |     dismissInspirationCard 
  42 |   } = useStarStore();
  43 |   
  44 |   const { messages } = useChatStore(); // 获取聊天消息以判断是否有对话历史
  45 |   // 处理后续提问的回调
  46 |   const handleFollowUpQuestion = (question: string) => {
  47 |     console.log('📱 App层接收到后续提问:', question);
  48 |     setPendingFollowUpQuestion(question);
  49 |     // 如果收到后续问题，打开对话浮层
  50 |     if (!isChatOverlayOpen) {
  51 |       setIsChatOverlayOpen(true);
  52 |     }
  53 |   };
  54 |   
  55 |   // 后续问题处理完成的回调
  56 |   const handleFollowUpProcessed = () => {
  57 |     console.log('📱 后续问题处理完成，清空pending状态');
  58 |     setPendingFollowUpQuestion('');
  59 |   };
  60 | 
  61 |   // 处理输入框聚焦，打开对话浮层
  62 |   const handleInputFocus = (inputText?: string) => {
  63 |     console.log('🔍 输入框被聚焦，打开对话浮层', inputText, 'isChatOverlayOpen:', isChatOverlayOpen);
  64 |     
  65 |     if (inputText) {
  66 |       if (isChatOverlayOpen) {
  67 |         // 如果浮窗已经打开，直接作为后续问题发送
  68 |         console.log('🔄 浮窗已打开，直接发送后续问题:', inputText);
  69 |         setPendingFollowUpQuestion(inputText);
  70 |       } else {
  71 |         // 如果浮窗未打开，设置为初始输入并打开浮窗
  72 |         console.log('🔄 浮窗未打开，设置初始输入并打开:', inputText);
  73 |         setInitialChatInput(inputText);
  74 |         setIsChatOverlayOpen(true);
  75 |       }
  76 |     } else {
  77 |       // 没有输入文本，只是打开浮窗
  78 |       setIsChatOverlayOpen(true);
  79 |     }
  80 |     
  81 |     // 立即清空初始输入，确保不重复处理
  82 |     setTimeout(() => {
  83 |       setInitialChatInput('');
  84 |     }, 500);
  85 |   };
  86 | 
  87 |   // ✨ 新增 handleSendMessage 函数
  88 |   // 当用户在输入框中按下发送时，此函数被调用
  89 |   const handleSendMessage = (inputText: string) => {
  90 |     console.log('🔍 App.tsx: 接收到发送请求，准备打开浮窗', inputText);
  91 | 
  92 |     // 只有在发送消息时才设置初始输入并打开浮窗
  93 |     if (isChatOverlayOpen) {
  94 |       // 如果浮窗已打开，直接作为后续问题发送
  95 |       console.log('🔄 浮窗已打开，直接发送后续问题:', inputText);
  96 |       setPendingFollowUpQuestion(inputText);
  97 |     } else {
  98 |       // 如果浮窗未打开，设置为初始输入并打开浮窗
  99 |       console.log('🔄 浮窗未打开，设置初始输入并打开:', inputText);
 100 |       setInitialChatInput(inputText);
 101 |       setIsChatOverlayOpen(true);
 102 |     }
 103 |   };
 104 | 
 105 |   // 关闭对话浮层
 106 |   const handleCloseChatOverlay = () => {
 107 |     console.log('❌ 关闭对话浮层');
 108 |     setIsChatOverlayOpen(false);
 109 |     setInitialChatInput(''); // 清空初始输入
 110 |   };
 111 | 
 112 |   // 添加原生平台效果（只在原生环境下执行）
 113 |   useEffect(() => {
 114 |     const setupNative = async () => {
 115 |       if (Capacitor.isNativePlatform()) {
 116 |         // 设置状态栏为暗色模式，文字为亮色
 117 |         await StatusBar.setStyle({ style: Style.Dark });
 118 |         
 119 |         // 标记应用准备就绪
 120 |         setAppReady(true);
 121 |         
 122 |         // 延迟隐藏启动屏，让应用完全加载
 123 |         setTimeout(async () => {
 124 |           await SplashScreen.hide({
 125 |             fadeOutDuration: 300
 126 |           });
 127 |         }, 500);
 128 |       } else {
 129 |         // Web环境立即设置为准备就绪
 130 |         setAppReady(true);
 131 |       }
 132 |     };
 133 |     setupNative();
 134 |   }, []);
 135 | 
 136 |   // 检查API配置（静默模式 - 只在控制台提示）
 137 |   useEffect(() => {
 138 |     // 延迟检查，确保应用已完全加载
 139 |     const timer = setTimeout(() => {
 140 |       const isConfigValid = checkApiConfiguration();
 141 |       // 移除UI警告，改为静默模式
 142 |       // setShowApiWarning(!isConfigValid);
 143 |       
 144 |       if (!isConfigValid) {
 145 |         console.warn('⚠️ API配置无效或不完整，请配置API以使用完整功能');
 146 |         console.info('💡 点击右上角设置图标进行API配置');
 147 |       } else {
 148 |         console.log('✅ API配置正常');
 149 |       }
 150 |     }, 2000);
 151 |     
 152 |     return () => clearTimeout(timer);
 153 |   }, []);
 154 | 
 155 |   // 监控灵感卡片状态变化（保持Web版本逻辑）
 156 |   useEffect(() => {
 157 |     console.log('🃏 灵感卡片状态变化:', currentInspirationCard ? '显示' : '隐藏');
 158 |     if (currentInspirationCard) {
 159 |       console.log('📝 当前卡片问题:', currentInspirationCard.question);
 160 |     }
 161 |   }, [currentInspirationCard]);
 162 | 
 163 |   // Start ambient sound when user interacts（延迟到用户交互后）
 164 |   useEffect(() => {
 165 |     const handleFirstInteraction = () => {
 166 |       startAmbientSound();
 167 |       document.removeEventListener('touchstart', handleFirstInteraction);
 168 |       document.removeEventListener('click', handleFirstInteraction);
 169 |     };
 170 |     
 171 |     document.addEventListener('touchstart', handleFirstInteraction);
 172 |     document.addEventListener('click', handleFirstInteraction);
 173 |     
 174 |     return () => {
 175 |       document.removeEventListener('touchstart', handleFirstInteraction);
 176 |       document.removeEventListener('click', handleFirstInteraction);
 177 |       stopAmbientSound();
 178 |     };
 179 |   }, []);
 180 | 
 181 |   const handleOpenCollection = () => {
 182 |     console.log('🔍 Collection button clicked - handleOpenCollection triggered!');
 183 |     // 添加触感反馈（仅原生环境）
 184 |     if (Capacitor.isNativePlatform()) {
 185 |       triggerHapticFeedback('light');
 186 |     }
 187 |     playSound('starLight');
 188 |     setIsCollectionOpen(true);
 189 |   };
 190 | 
 191 |   const handleCloseCollection = () => {
 192 |     // 添加触感反馈（仅原生环境）
 193 |     if (Capacitor.isNativePlatform()) {
 194 |       triggerHapticFeedback('light');
 195 |     }
 196 |     setIsCollectionOpen(false);
 197 |   };
 198 | 
 199 |   const handleOpenConfig = () => {
 200 |     console.log('⚙️ Settings button clicked - handleOpenConfig triggered!');
 201 |     // 添加触感反馈（仅原生环境）
 202 |     if (Capacitor.isNativePlatform()) {
 203 |       triggerHapticFeedback('medium');
 204 |     }
 205 |     playSound('starClick');
 206 |     setIsConfigOpen(true);
 207 |   };
 208 | 
 209 |   const handleCloseConfig = () => {
 210 |     // 添加触感反馈（仅原生环境）
 211 |     if (Capacitor.isNativePlatform()) {
 212 |       triggerHapticFeedback('light');
 213 |     }
 214 |     setIsConfigOpen(false);
 215 |     // 静默模式：移除配置检查和UI提示
 216 |   };
 217 | 
 218 |   const handleOpenDrawerMenu = () => {
 219 |     console.log('🍔 Menu button clicked - handleOpenDrawerMenu triggered!');
 220 |     // 添加触感反馈（仅原生环境）
 221 |     if (Capacitor.isNativePlatform()) {
 222 |       triggerHapticFeedback('light');
 223 |     }
 224 |     playSound('starClick');
 225 |     setIsDrawerMenuOpen(true);
 226 |   };
 227 | 
 228 |   const handleCloseDrawerMenu = () => {
 229 |     // 添加触感反馈（仅原生环境）
 230 |     if (Capacitor.isNativePlatform()) {
 231 |       triggerHapticFeedback('light');
 232 |     }
 233 |     setIsDrawerMenuOpen(false);
 234 |   };
 235 | 
 236 |   const handleLogoClick = () => {
 237 |     console.log('✦ Logo button clicked - opening StarCollection!');
 238 |     // 添加触感反馈（仅原生环境）
 239 |     if (Capacitor.isNativePlatform()) {
 240 |       triggerHapticFeedback('light');
 241 |     }
 242 |     playSound('starLight');
 243 |     setIsCollectionOpen(true);
 244 |   };
 245 | 
 246 |   const handleOpenTemplateSelector = () => {
 247 |     // 添加触感反馈（仅原生环境）
 248 |     if (Capacitor.isNativePlatform()) {
 249 |       triggerHapticFeedback('light');
 250 |     }
 251 |     playSound('starClick');
 252 |     setIsTemplateSelectorOpen(true);
 253 |   };
 254 | 
 255 |   const handleCloseTemplateSelector = () => {
 256 |     // 添加触感反馈（仅原生环境）
 257 |     if (Capacitor.isNativePlatform()) {
 258 |       triggerHapticFeedback('light');
 259 |     }
 260 |     setIsTemplateSelectorOpen(false);
 261 |   };
 262 | 
 263 |   const handleSelectTemplate = (template: ConstellationTemplate) => {
 264 |     // 添加触感反馈（仅原生环境）
 265 |     if (Capacitor.isNativePlatform()) {
 266 |       triggerHapticFeedback('success');
 267 |     }
 268 |     applyTemplate(template);
 269 |     playSound('starReveal');
 270 |   };
 271 |   
 272 |   return (
 273 |     <>
 274 |       <div 
 275 |         className="min-h-screen cosmic-bg overflow-hidden relative transition-all duration-500 ease-out"
 276 |         style={{
 277 |           transformStyle: 'preserve-3d',
 278 |           perspective: '1000px',
 279 |           transform: isChatOverlayOpen
 280 |             ? 'scale(0.92) translateY(-15px) rotateX(4deg)' 
 281 |             : 'scale(1) translateY(0px) rotateX(0deg)',
 282 |           filter: isChatOverlayOpen ? 'brightness(0.6)' : 'brightness(1)'
 283 |         }}
 284 |       >
 285 |         {/* Background with stars - 已屏蔽 */}
 286 |         {/* {appReady && <StarryBackground starCount={75} />} */}
 287 |         
 288 |         {/* Header - 现在包含三个元素在一行 */}
 289 |         <Header 
 290 |           onOpenDrawerMenu={handleOpenDrawerMenu}
 291 |           onLogoClick={handleLogoClick}
 292 |         />
 293 | 
 294 |         {/* User's constellation - 延迟渲染 */}
 295 |         {appReady && <Constellation />}
 296 |         
 297 |         {/* Inspiration card */}
 298 |         {currentInspirationCard && (
 299 |           <InspirationCard
 300 |             card={currentInspirationCard}
 301 |             onDismiss={dismissInspirationCard}
 302 |           />
 303 |         )}
 304 |         
 305 |         {/* Star detail modal */}
 306 |         {appReady && <StarDetail />}
 307 |         
 308 |         {/* Star collection modal */}
 309 |         <StarCollection 
 310 |           isOpen={isCollectionOpen} 
 311 |           onClose={handleCloseCollection} 
 312 |         />
 313 | 
 314 |         {/* Template selector modal */}
 315 |         <ConstellationSelector
 316 |           isOpen={isTemplateSelectorOpen}
 317 |           onClose={handleCloseTemplateSelector}
 318 |           onSelectTemplate={handleSelectTemplate}
 319 |         />
 320 | 
 321 |         {/* AI Configuration Panel */}
 322 |         <AIConfigPanel
 323 |           isOpen={isConfigOpen}
 324 |           onClose={handleCloseConfig}
 325 |         />
 326 | 
 327 |         {/* Drawer Menu */}
 328 |         <DrawerMenu
 329 |           isOpen={isDrawerMenuOpen}
 330 |           onClose={handleCloseDrawerMenu}
 331 |           onOpenSettings={handleOpenConfig}
 332 |           onOpenTemplateSelector={handleOpenTemplateSelector}
 333 |         />
 334 | 
 335 |         {/* Oracle Input for star creation */}
 336 |         <OracleInput />
 337 |       </div>
 338 |       
 339 |       {/* Conversation Drawer - 移到外层，不受3D变换影响 */}
 340 |       <ConversationDrawer 
 341 |         isOpen={true} 
 342 |         onToggle={() => {}} 
 343 |         onSendMessage={handleSendMessage} // ✨ 使用新的回调
 344 |         showChatHistory={false}
 345 |         isFloatingAttached={!isChatOverlayOpen} // 浮窗关闭时为吸附状态
 346 |       />
 347 |       
 348 |       {/* Chat Overlay - 移到最外层，不受cosmic-bg的3D变换影响 */}
 349 |       <ChatOverlay
 350 |         isOpen={isChatOverlayOpen}
 351 |         onClose={handleCloseChatOverlay}
 352 |         onReopen={() => setIsChatOverlayOpen(true)}
 353 |         followUpQuestion={pendingFollowUpQuestion}
 354 |         onFollowUpProcessed={handleFollowUpProcessed}
 355 |         initialInput={initialChatInput}
 356 |         inputBottomSpace={isChatOverlayOpen ? 34 : 70} // 根据浮窗状态传递不同的底部空间
 357 |       />
 358 |     </>
 359 |   );
 360 | }
 361 | 
 362 | export default App;

```

`staroracle-app_allreact/src/ErrorBoundary.tsx`:

```tsx
   1 | import React, { Component, ReactNode } from 'react';
   2 | 
   3 | interface Props {
   4 |   children: ReactNode;
   5 | }
   6 | 
   7 | interface State {
   8 |   hasError: boolean;
   9 |   error?: Error;
  10 | }
  11 | 
  12 | class ErrorBoundary extends Component<Props, State> {
  13 |   constructor(props: Props) {
  14 |     super(props);
  15 |     this.state = { hasError: false };
  16 |   }
  17 | 
  18 |   static getDerivedStateFromError(error: Error): State {
  19 |     return { hasError: true, error };
  20 |   }
  21 | 
  22 |   componentDidCatch(error: Error, errorInfo: any) {
  23 |     console.error('App Error Boundary caught an error:', error, errorInfo);
  24 |   }
  25 | 
  26 |   render() {
  27 |     if (this.state.hasError) {
  28 |       return (
  29 |         <div className="min-h-screen bg-black relative flex items-center justify-center">
  30 |           <div className="text-white bg-red-500 p-4 rounded max-w-md">
  31 |             <h2 className="text-xl mb-2">Application Error</h2>
  32 |             <p className="mb-2">Something went wrong:</p>
  33 |             <pre className="text-sm bg-black p-2 rounded overflow-auto">
  34 |               {this.state.error?.message}
  35 |             </pre>
  36 |             <button 
  37 |               onClick={() => this.setState({ hasError: false })}
  38 |               className="mt-2 px-4 py-2 bg-blue-500 rounded text-white"
  39 |             >
  40 |               Try Again
  41 |             </button>
  42 |           </div>
  43 |         </div>
  44 |       );
  45 |     }
  46 | 
  47 |     return this.props.children;
  48 |   }
  49 | }
  50 | 
  51 | export default ErrorBoundary;

```

`staroracle-app_allreact/src/components/AIConfigPanel.tsx`:

```tsx
   1 | import React, { useState, useRef, useEffect } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { Settings, X, Key, Globe, Cpu, CheckCircle, XCircle, Loader, Download, Upload, Clock } from 'lucide-react';
   5 | import { setAIConfig, getAIConfig, validateAIConfig, APIValidationResult, clearAIConfig } from '../utils/aiTaggingUtils';
   6 | import { playSound } from '../utils/soundUtils';
   7 | import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
   8 | import type { ApiProvider } from '../vite-env';
   9 | 
  10 | interface AIConfigPanelProps {
  11 |   isOpen: boolean;
  12 |   onClose: () => void;
  13 | }
  14 | 
  15 | const AIConfigPanel: React.FC<AIConfigPanelProps> = ({ isOpen, onClose }) => {
  16 |   const [config, setConfig] = useState(() => getAIConfig());
  17 |   const [isSaving, setIsSaving] = useState(false);
  18 |   const [isValidating, setIsValidating] = useState(false);
  19 |   const [validationResult, setValidationResult] = useState<APIValidationResult | null>(null);
  20 |   const [showLastUpdated, setShowLastUpdated] = useState(false);
  21 |   const [provider, setProvider] = useState<ApiProvider>(config.provider || 'openai');
  22 |   const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  23 |   
  24 |   // 添加refs用于直接访问DOM元素
  25 |   const apiKeyRef = useRef<HTMLInputElement>(null);
  26 |   const endpointRef = useRef<HTMLInputElement>(null);
  27 |   const modelRef = useRef<HTMLInputElement>(null);
  28 |   const fileInputRef = useRef<HTMLInputElement>(null);
  29 | 
  30 |   // 初始化iOS层级修复
  31 |   useEffect(() => {
  32 |     fixIOSZIndex();
  33 |   }, []);
  34 | 
  35 |   // 当模态框打开时隐藏其他元素
  36 |   useEffect(() => {
  37 |     if (isOpen) {
  38 |       document.body.classList.add('modal-open');
  39 |       const restore = hideOtherElements();
  40 |       setRestoreElements(() => restore);
  41 |     } else {
  42 |       document.body.classList.remove('modal-open');
  43 |       if (restoreElements) {
  44 |         restoreElements();
  45 |         setRestoreElements(null);
  46 |       }
  47 |     }
  48 |     
  49 |     return () => {
  50 |       document.body.classList.remove('modal-open');
  51 |       if (restoreElements) {
  52 |         restoreElements();
  53 |       }
  54 |     };
  55 |   }, [isOpen]);
  56 | 
  57 |   // 当组件打开时，确保输入框可以接受粘贴
  58 |   useEffect(() => {
  59 |     if (isOpen) {
  60 |       const handlePaste = (e: ClipboardEvent) => {
  61 |         // 允许默认粘贴行为
  62 |         e.stopPropagation();
  63 |       };
  64 | 
  65 |       // 为所有输入框添加粘贴事件监听
  66 |       const elements = [apiKeyRef.current, endpointRef.current, modelRef.current];
  67 |       elements.forEach(el => {
  68 |         if (el) {
  69 |           el.addEventListener('paste', handlePaste);
  70 |         }
  71 |       });
  72 | 
  73 |       // 设置当前provider
  74 |       setProvider(config.provider || 'openai');
  75 | 
  76 |       return () => {
  77 |         // 清理事件监听
  78 |         elements.forEach(el => {
  79 |           if (el) {
  80 |             el.removeEventListener('paste', handlePaste);
  81 |           }
  82 |         });
  83 |       };
  84 |     }
  85 |   }, [isOpen, config]);
  86 | 
  87 |   const handleProviderChange = (value: ApiProvider) => {
  88 |     setProvider(value);
  89 |     setConfig({
  90 |       ...config,
  91 |       provider: value
  92 |     });
  93 | 
  94 |     // 根据选择的provider设置不同的endpoint和model示例
  95 |     if (value === 'gemini') {
  96 |       if (!config.endpoint || config.endpoint.includes('openai.com')) {
  97 |         setConfig(prev => ({
  98 |           ...prev,
  99 |           endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent',
 100 |           model: 'gemini-1.5-flash-latest'
 101 |         }));
 102 |       }
 103 |     } else if (value === 'openai') {
 104 |       if (!config.endpoint || config.endpoint.includes('googleapis.com')) {
 105 |         setConfig(prev => ({
 106 |           ...prev,
 107 |           endpoint: 'https://api.openai.com/v1/chat/completions',
 108 |           model: 'gpt-4o'
 109 |         }));
 110 |       }
 111 |     }
 112 |   };
 113 | 
 114 |   const handleValidate = async () => {
 115 |     if (!config.provider || !config.apiKey || !config.endpoint || !config.model) {
 116 |       setValidationResult({
 117 |         isValid: false,
 118 |         error: '请填写完整的配置信息'
 119 |       });
 120 |       return;
 121 |     }
 122 | 
 123 |     setIsValidating(true);
 124 |     setValidationResult(null);
 125 |     playSound('starClick');
 126 | 
 127 |     try {
 128 |       const result = await validateAIConfig(config);
 129 |       setValidationResult(result);
 130 |       
 131 |       if (result.isValid) {
 132 |         playSound('starReveal');
 133 |       } else {
 134 |         playSound('starClick');
 135 |       }
 136 |     } catch (error) {
 137 |       setValidationResult({
 138 |         isValid: false,
 139 |         error: '验证过程中发生错误'
 140 |       });
 141 |     } finally {
 142 |       setIsValidating(false);
 143 |     }
 144 |   };
 145 | 
 146 |   const handleSave = async () => {
 147 |     setIsSaving(true);
 148 |     playSound('starLight');
 149 |     
 150 |     try {
 151 |       setAIConfig(config);
 152 |       // Test the configuration
 153 |       await new Promise(resolve => setTimeout(resolve, 1000));
 154 |       playSound('starReveal');
 155 |       onClose();
 156 |     } catch (error) {
 157 |       console.error('Failed to save AI config:', error);
 158 |     } finally {
 159 |       setIsSaving(false);
 160 |     }
 161 |   };
 162 | 
 163 |   const handleClose = () => {
 164 |     playSound('starClick');
 165 |     onClose();
 166 |   };
 167 | 
 168 |   const getValidationIcon = () => {
 169 |     if (isValidating) {
 170 |       return <Loader className="w-4 h-4 animate-spin text-blue-400" />;
 171 |     }
 172 |     if (validationResult?.isValid) {
 173 |       return <CheckCircle className="w-4 h-4 text-green-400" />;
 174 |     }
 175 |     if (validationResult && !validationResult.isValid) {
 176 |       return <XCircle className="w-4 h-4 text-red-400" />;
 177 |     }
 178 |     return null;
 179 |   };
 180 | 
 181 |   const getValidationMessage = () => {
 182 |     if (isValidating) {
 183 |       return "正在验证API配置...";
 184 |     }
 185 |     if (validationResult?.isValid) {
 186 |       return `✅ API验证成功！响应时间: ${validationResult.responseTime}ms`;
 187 |     }
 188 |     if (validationResult && !validationResult.isValid) {
 189 |       return `❌ ${validationResult.error}`;
 190 |     }
 191 |     return null;
 192 |   };
 193 | 
 194 |   // 导出配置到文件
 195 |   const handleExportConfig = () => {
 196 |     try {
 197 |       const configData = JSON.stringify({
 198 |         provider: config.provider,
 199 |         apiKey: config.apiKey,
 200 |         endpoint: config.endpoint,
 201 |         model: config.model,
 202 |         exportDate: new Date().toISOString()
 203 |       }, null, 2);
 204 |       
 205 |       const blob = new Blob([configData], { type: 'application/json' });
 206 |       const url = URL.createObjectURL(blob);
 207 |       
 208 |       const a = document.createElement('a');
 209 |       a.href = url;
 210 |       a.download = `stelloracle-config-${new Date().toISOString().slice(0, 10)}.json`;
 211 |       document.body.appendChild(a);
 212 |       a.click();
 213 |       
 214 |       setTimeout(() => {
 215 |         document.body.removeChild(a);
 216 |         URL.revokeObjectURL(url);
 217 |       }, 0);
 218 |       
 219 |       playSound('starLight');
 220 |     } catch (error) {
 221 |       console.error('导出配置失败:', error);
 222 |     }
 223 |   };
 224 | 
 225 |   // 导入配置
 226 |   const handleImportConfig = () => {
 227 |     if (fileInputRef.current) {
 228 |       fileInputRef.current.click();
 229 |     }
 230 |   };
 231 | 
 232 |   const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
 233 |     const file = e.target.files?.[0];
 234 |     if (!file) return;
 235 |     
 236 |     const reader = new FileReader();
 237 |     reader.onload = (event) => {
 238 |       try {
 239 |         const importedConfig = JSON.parse(event.target?.result as string);
 240 |         
 241 |         // 验证导入的配置
 242 |         if (importedConfig.apiKey && importedConfig.endpoint) {
 243 |           const newConfig = {
 244 |             provider: importedConfig.provider || 'openai',
 245 |             apiKey: importedConfig.apiKey,
 246 |             endpoint: importedConfig.endpoint,
 247 |             model: importedConfig.model || config.model
 248 |           };
 249 |           
 250 |           setConfig(newConfig);
 251 |           setProvider(newConfig.provider);
 252 |           playSound('starReveal');
 253 |         } else {
 254 |           console.error('导入的配置格式不正确');
 255 |         }
 256 |       } catch (error) {
 257 |         console.error('解析导入的配置失败:', error);
 258 |       }
 259 |       
 260 |       // 重置文件输入，以便可以再次选择同一文件
 261 |       if (fileInputRef.current) {
 262 |         fileInputRef.current.value = '';
 263 |       }
 264 |     };
 265 |     
 266 |     reader.readAsText(file);
 267 |   };
 268 | 
 269 |   // 格式化最后更新时间
 270 |   const formatLastUpdated = (dateString?: string) => {
 271 |     if (!dateString) return '未知';
 272 |     try {
 273 |       const date = new Date(dateString);
 274 |       return date.toLocaleString('zh-CN');
 275 |     } catch (e) {
 276 |       return dateString;
 277 |     }
 278 |   };
 279 | 
 280 |   return createPortal(
 281 |     <AnimatePresence>
 282 |       {isOpen && (
 283 |         <motion.div
 284 |           className={getMobileModalClasses()}
 285 |           style={getMobileModalStyles()}
 286 |           initial={{ opacity: 0 }}
 287 |           animate={{ opacity: 1 }}
 288 |           exit={{ opacity: 0 }}
 289 |         >
 290 |           <motion.div
 291 |             className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
 292 |             initial={{ opacity: 0 }}
 293 |             animate={{ opacity: 1 }}
 294 |             exit={{ opacity: 0 }}
 295 |             onClick={handleClose}
 296 |           />
 297 | 
 298 |           <motion.div
 299 |             className="cosmic-input rounded-lg w-full max-w-md mx-4 z-10"
 300 |             initial={{ opacity: 0, y: 20, scale: 0.9 }}
 301 |             animate={{ opacity: 1, y: 0, scale: 1 }}
 302 |             exit={{ opacity: 0, y: 20, scale: 0.9 }}
 303 |             transition={{ type: 'spring', damping: 25 }}
 304 |           >
 305 |             <div className="p-6">
 306 |               {/* Header */}
 307 |               <div className="flex items-center justify-between mb-6">
 308 |                 <div className="flex items-center gap-3">
 309 |                   <Settings className="w-6 h-6 text-cosmic-accent" />
 310 |                   <h2 className="stellar-title text-white">AI Configuration</h2>
 311 |                 </div>
 312 |                 <button
 313 |                   className="w-8 h-8 rounded-full cosmic-button flex items-center justify-center"
 314 |                   onClick={handleClose}
 315 |                 >
 316 |                   <X className="w-4 h-4 text-white" />
 317 |                 </button>
 318 |               </div>
 319 |               
 320 |               {/* API Provider Selection */}
 321 |               <div className="mb-6">
 322 |                 <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
 323 |                   <Globe className="w-4 h-4 mr-2" />
 324 |                   API 提供商
 325 |                 </label>
 326 |                 <div className="flex gap-3">
 327 |                   <button
 328 |                     className={`flex-1 py-2 px-3 rounded-md text-sm flex items-center justify-center gap-2 transition-colors ${
 329 |                       provider === 'openai' 
 330 |                         ? 'bg-cosmic-accent text-white' 
 331 |                         : 'cosmic-button text-gray-300'
 332 |                     }`}
 333 |                     onClick={() => handleProviderChange('openai')}
 334 |                   >
 335 |                     OpenAI / 兼容服务
 336 |                   </button>
 337 |                   <button
 338 |                     className={`flex-1 py-2 px-3 rounded-md text-sm flex items-center justify-center gap-2 transition-colors ${
 339 |                       provider === 'gemini' 
 340 |                         ? 'bg-cosmic-accent text-white' 
 341 |                         : 'cosmic-button text-gray-300'
 342 |                     }`}
 343 |                     onClick={() => handleProviderChange('gemini')}
 344 |                   >
 345 |                     Google Gemini
 346 |                   </button>
 347 |                 </div>
 348 |               </div>
 349 | 
 350 |               {/* API Key */}
 351 |               <div className="mb-6">
 352 |                 <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
 353 |                   <Key className="w-4 h-4 mr-2" />
 354 |                   API Key
 355 |                 </label>
 356 |                 <input
 357 |                   ref={apiKeyRef}
 358 |                   type="password"
 359 |                   className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
 360 |                   placeholder={provider === 'gemini' ? "Google API Key" : "OpenAI API Key"}
 361 |                   value={config.apiKey || ''}
 362 |                   onChange={(e) => setConfig({ ...config, apiKey: e.target.value })}
 363 |                 />
 364 |               </div>
 365 | 
 366 |               {/* Endpoint */}
 367 |               <div className="mb-6">
 368 |                 <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
 369 |                   <Globe className="w-4 h-4 mr-2" />
 370 |                   API Endpoint
 371 |                 </label>
 372 |                 <input
 373 |                   ref={endpointRef}
 374 |                   type="text"
 375 |                   className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
 376 |                   placeholder={
 377 |                     provider === 'gemini' 
 378 |                       ? "https://generativelanguage.googleapis.com/..." 
 379 |                       : "https://api.openai.com/v1/chat/completions"
 380 |                   }
 381 |                   value={config.endpoint || ''}
 382 |                   onChange={(e) => setConfig({ ...config, endpoint: e.target.value })}
 383 |                 />
 384 |               </div>
 385 | 
 386 |               {/* Model */}
 387 |               <div className="mb-6">
 388 |                 <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
 389 |                   <Cpu className="w-4 h-4 mr-2" />
 390 |                   模型名称
 391 |                 </label>
 392 |                 <input
 393 |                   ref={modelRef}
 394 |                   type="text"
 395 |                   className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
 396 |                   placeholder={provider === 'gemini' ? "gemini-1.5-flash-latest" : "gpt-4o"}
 397 |                   value={config.model || ''}
 398 |                   onChange={(e) => setConfig({ ...config, model: e.target.value })}
 399 |                 />
 400 |               </div>
 401 | 
 402 |               {/* Validation Result */}
 403 |               {(isValidating || validationResult) && (
 404 |                 <div className={`mb-6 p-3 rounded-md flex items-start gap-2 text-sm ${
 405 |                   validationResult?.isValid 
 406 |                     ? 'bg-green-500 bg-opacity-20 text-green-300' 
 407 |                     : 'bg-red-500 bg-opacity-20 text-red-300'
 408 |                 }`}>
 409 |                   {getValidationIcon()}
 410 |                   <div>{getValidationMessage()}</div>
 411 |                 </div>
 412 |               )}
 413 | 
 414 |               {/* Last Updated */}
 415 |               {config._lastUpdated && (
 416 |                 <div className="mb-6">
 417 |                   <button
 418 |                     className="text-xs text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
 419 |                     onClick={() => setShowLastUpdated(!showLastUpdated)}
 420 |                   >
 421 |                     <Clock className="w-3 h-3" />
 422 |                     {showLastUpdated 
 423 |                       ? `最后更新: ${formatLastUpdated(config._lastUpdated)}` 
 424 |                       : '显示最后更新时间'}
 425 |                   </button>
 426 |                 </div>
 427 |               )}
 428 | 
 429 |               {/* Actions */}
 430 |               <div className="flex flex-wrap gap-3">
 431 |                 <button
 432 |                   className="flex-1 py-2 px-4 cosmic-button text-white rounded-md flex items-center justify-center gap-2 transition-colors"
 433 |                   onClick={handleValidate}
 434 |                   disabled={isValidating}
 435 |                 >
 436 |                   {isValidating ? (
 437 |                     <Loader className="w-4 h-4 animate-spin" />
 438 |                   ) : (
 439 |                     <CheckCircle className="w-4 h-4" />
 440 |                   )}
 441 |                   验证
 442 |                 </button>
 443 |                 <button
 444 |                   className="flex-1 py-2 px-4 bg-cosmic-accent hover:bg-cosmic-accent-dark text-white rounded-md flex items-center justify-center gap-2 transition-colors"
 445 |                   onClick={handleSave}
 446 |                   disabled={isSaving}
 447 |                 >
 448 |                   {isSaving ? (
 449 |                     <Loader className="w-4 h-4 animate-spin" />
 450 |                   ) : (
 451 |                     <Settings className="w-4 h-4" />
 452 |                   )}
 453 |                   保存
 454 |                 </button>
 455 |               </div>
 456 | 
 457 |               {/* Import/Export */}
 458 |               <div className="mt-4 flex justify-between">
 459 |                 <button
 460 |                   className="text-sm text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
 461 |                   onClick={handleImportConfig}
 462 |                 >
 463 |                   <Upload className="w-4 h-4" />
 464 |                   导入配置
 465 |                 </button>
 466 |                 <input
 467 |                   ref={fileInputRef}
 468 |                   type="file"
 469 |                   accept=".json"
 470 |                   style={{ display: 'none' }}
 471 |                   onChange={handleFileChange}
 472 |                 />
 473 |                 <button
 474 |                   className="text-sm text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
 475 |                   onClick={handleExportConfig}
 476 |                 >
 477 |                   <Download className="w-4 h-4" />
 478 |                   导出配置
 479 |                 </button>
 480 |               </div>
 481 |             </div>
 482 |           </motion.div>
 483 |         </motion.div>
 484 |       )}
 485 |     </AnimatePresence>,
 486 |     createTopLevelContainer()
 487 |   );
 488 | };
 489 | 
 490 | export default AIConfigPanel;

```

`staroracle-app_allreact/src/components/AIMessage.tsx`:

```tsx
   1 | import React, { useState, useEffect, useRef } from 'react';
   2 | import { Copy, RotateCcw, ThumbsUp, ThumbsDown, Download } from 'lucide-react';
   3 | import { ChatMessage } from '../types/chat';
   4 | import StarLoadingAnimation from './StarLoadingAnimation';
   5 | import AwarenessIcon from './AwarenessIcon';
   6 | import AwarenessDetailModal from './AwarenessDetailModal';
   7 | import MessageContextMenu from './MessageContextMenu';
   8 | import { analyzeAwarenessValue } from '../utils/aiTaggingUtils';
   9 | import { useChatStore } from '../store/useChatStore';
  10 | 
  11 | interface AIMessageProps {
  12 |   message: ChatMessage;
  13 |   userQuestion?: string; // 对应的用户问题，用于觉察分析
  14 |   onAskFollowUp?: (question: string) => void; // 后续提问回调
  15 | }
  16 | 
  17 | const AIMessage: React.FC<AIMessageProps> = ({ message, userQuestion, onAskFollowUp }) => {
  18 |   const [showAwarenessModal, setShowAwarenessModal] = useState(false);
  19 |   const [contextMenu, setContextMenu] = useState({ isVisible: false, x: 0, y: 0 });
  20 |   const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
  21 |   const messageRef = useRef<HTMLDivElement>(null);
  22 |   const { startAwarenessAnalysis, completeAwarenessAnalysis } = useChatStore();
  23 |   
  24 |   // 在消息完成流式输出后，自动进行觉察分析
  25 |   useEffect(() => {
  26 |     if (!message.isStreaming && 
  27 |         message.text && 
  28 |         userQuestion && 
  29 |         !message.awarenessInsight && 
  30 |         !message.isAnalyzingAwareness) {
  31 |       
  32 |       console.log('🧠 开始对完成的对话进行觉察分析...');
  33 |       handleAwarenessAnalysis();
  34 |     }
  35 |   }, [message.isStreaming, message.text, userQuestion, message.awarenessInsight, message.isAnalyzingAwareness]);
  36 |   
  37 |   // 执行觉察分析
  38 |   const handleAwarenessAnalysis = async () => {
  39 |     if (!userQuestion || !message.text) return;
  40 |     
  41 |     console.log('🔍 触发觉察分析:', { userQuestion, aiResponse: message.text });
  42 |     
  43 |     // 标记为正在分析
  44 |     startAwarenessAnalysis(message.id);
  45 |     
  46 |     try {
  47 |       const insight = await analyzeAwarenessValue(userQuestion, message.text);
  48 |       console.log('✅ 觉察分析结果:', insight);
  49 |       
  50 |       // 完成分析，保存结果
  51 |       completeAwarenessAnalysis(message.id, insight);
  52 |     } catch (error) {
  53 |       console.error('❌ 觉察分析失败:', error);
  54 |       // 分析失败时也要取消加载状态
  55 |       completeAwarenessAnalysis(message.id, {
  56 |         hasInsight: false,
  57 |         insightLevel: 'low',
  58 |         insightType: '一般对话',
  59 |         keyInsights: [],
  60 |         emotionalPattern: '无特殊模式',
  61 |         suggestedReflection: '可以继续探索其他话题',
  62 |         followUpQuestions: []
  63 |       });
  64 |     }
  65 |   };
  66 | 
  67 |   const handleCopy = () => {
  68 |     navigator.clipboard.writeText(message.text);
  69 |     console.log('Message copied to clipboard');
  70 |   };
  71 | 
  72 |   const handleRegenerate = () => {
  73 |     console.log('Regenerate message');
  74 |   };
  75 | 
  76 |   const handleThumbsUp = () => {
  77 |     console.log('Message liked');
  78 |   };
  79 | 
  80 |   const handleThumbsDown = () => {
  81 |     console.log('Message disliked');
  82 |   };
  83 | 
  84 |   const handleDownload = () => {
  85 |     console.log('Download message');
  86 |   };
  87 |   
  88 |   // 长按处理函数
  89 |   const handleLongPress = (event: React.TouchEvent | React.MouseEvent) => {
  90 |     event.preventDefault();
  91 |     const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
  92 |     const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
  93 |     
  94 |     setContextMenu({
  95 |       isVisible: true,
  96 |       x: clientX,
  97 |       y: clientY
  98 |     });
  99 |     
 100 |     console.log('显示AI消息上下文菜单', { x: clientX, y: clientY });
 101 |   };
 102 |   
 103 |   // 触摸开始
 104 |   const handleTouchStart = (event: React.TouchEvent) => {
 105 |     const timer = setTimeout(() => {
 106 |       handleLongPress(event);
 107 |     }, 500); // 500ms长按
 108 |     setLongPressTimer(timer);
 109 |   };
 110 |   
 111 |   // 触摸结束或取消
 112 |   const handleTouchEnd = () => {
 113 |     if (longPressTimer) {
 114 |       clearTimeout(longPressTimer);
 115 |       setLongPressTimer(null);
 116 |     }
 117 |   };
 118 |   
 119 |   // 鼠标右键点击
 120 |   const handleContextMenu = (event: React.MouseEvent) => {
 121 |     event.preventDefault();
 122 |     handleLongPress(event);
 123 |   };
 124 |   
 125 |   // 关闭上下文菜单
 126 |   const handleCloseContextMenu = () => {
 127 |     setContextMenu({ isVisible: false, x: 0, y: 0 });
 128 |   };
 129 |   
 130 |   // 复制消息
 131 |   const handleContextMenuCopy = () => {
 132 |     navigator.clipboard.writeText(message.text);
 133 |     console.log('通过上下文菜单复制消息');
 134 |   };
 135 |   
 136 |   // 标准化文本格式，统一换行符和段落间距
 137 |   const normalizeText = (text: string): string => {
 138 |     if (!text) return '';
 139 |     
 140 |     return text
 141 |       // 统一换行符为 \n
 142 |       .replace(/\r\n/g, '\n')
 143 |       .replace(/\r/g, '\n')
 144 |       // 将连续的多个换行符（2个或以上）替换为单个段落分隔符
 145 |       .replace(/\n{2,}/g, '\n\n')
 146 |       // 移除行首行尾的空白字符，但保留换行结构
 147 |       .split('\n')
 148 |       .map(line => line.trim())
 149 |       .join('\n')
 150 |       // 最后清理开头结尾的多余换行
 151 |       .replace(/^\n+|\n+$/g, '');
 152 |   };
 153 | 
 154 |   return (
 155 |     <div className="flex justify-start mb-4">
 156 |       <div className="max-w-[80%]">
 157 |         <div className="py-2 text-white stellar-body">
 158 |           {message.isStreaming && !message.text ? (
 159 |             // 显示星星加载动画（当消息为空且正在流式加载时）
 160 |             <StarLoadingAnimation size={20} className="py-1" />
 161 |           ) : (
 162 |             // 显示消息内容
 163 |             <div 
 164 |               ref={messageRef}
 165 |               className="whitespace-pre-wrap break-words chat-message-content"
 166 |               onTouchStart={handleTouchStart}
 167 |               onTouchEnd={handleTouchEnd}
 168 |               onTouchCancel={handleTouchEnd}
 169 |               onContextMenu={handleContextMenu}
 170 |             >
 171 |               {normalizeText(message.text)}
 172 |               {message.isStreaming && message.text && (
 173 |                 // 流式输出时在文字后显示光标
 174 |                 <span className="inline-block w-2 h-4 bg-white ml-1 animate-pulse"></span>
 175 |               )}
 176 |             </div>
 177 |           )}
 178 |         </div>
 179 |         
 180 |         {/* AI消息操作按钮 - 只在非流式状态下显示 */}
 181 |         {!message.isStreaming && (
 182 |           <div className="flex items-center gap-2 mt-2 ml-2">
 183 |             {/* 觉察图标 - 显示在所有按钮最前面 */}
 184 |             <AwarenessIcon
 185 |               level={message.awarenessInsight?.insightLevel || 'low'}
 186 |               isActive={message.awarenessInsight?.hasInsight || false}
 187 |               isAnalyzing={message.isAnalyzingAwareness || false}
 188 |               size={18}
 189 |               onClick={() => {
 190 |                 if (message.awarenessInsight) {
 191 |                   setShowAwarenessModal(true);
 192 |                 }
 193 |               }}
 194 |             />
 195 |             
 196 |             <button 
 197 |               onClick={handleCopy}
 198 |               className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
 199 |               title="复制"
 200 |             >
 201 |               <Copy className="w-4 h-4" />
 202 |             </button>
 203 |             
 204 |             <button 
 205 |               onClick={handleRegenerate}
 206 |               className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
 207 |               title="重新生成"
 208 |             >
 209 |               <RotateCcw className="w-4 h-4" />
 210 |             </button>
 211 |             
 212 |             <button 
 213 |               onClick={handleThumbsUp}
 214 |               className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
 215 |               title="赞"
 216 |             >
 217 |               <ThumbsUp className="w-4 h-4" />
 218 |             </button>
 219 |             
 220 |             <button 
 221 |               onClick={handleThumbsDown}
 222 |               className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
 223 |               title="踩"
 224 |             >
 225 |               <ThumbsDown className="w-4 h-4" />
 226 |             </button>
 227 |             
 228 |             <button 
 229 |               onClick={handleDownload}
 230 |               className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
 231 |               title="下载"
 232 |             >
 233 |               <Download className="w-4 h-4" />
 234 |             </button>
 235 |           </div>
 236 |         )}
 237 |         
 238 |         {/* 觉察详情弹窗 */}
 239 |         {message.awarenessInsight && (
 240 |           <AwarenessDetailModal
 241 |             isOpen={showAwarenessModal}
 242 |             onClose={() => setShowAwarenessModal(false)}
 243 |             insight={message.awarenessInsight}
 244 |             onAskFollowUp={(question) => {
 245 |               if (onAskFollowUp) {
 246 |                 onAskFollowUp(question);
 247 |               }
 248 |             }}
 249 |           />
 250 |         )}
 251 |         
 252 |         {/* 时间戳 - 只在非流式状态下显示 */}
 253 |         {!message.isStreaming && (
 254 |           <div className="text-xs text-gray-400 mt-1 ml-2">
 255 |             {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
 256 |           </div>
 257 |         )}
 258 |         
 259 |         {/* 上下文菜单 */}
 260 |         <MessageContextMenu
 261 |           isVisible={contextMenu.isVisible}
 262 |           position={{ x: contextMenu.x, y: contextMenu.y }}
 263 |           messageText={message.text}
 264 |           onClose={handleCloseContextMenu}
 265 |           onCopy={handleContextMenuCopy}
 266 |         />
 267 |       </div>
 268 |     </div>
 269 |   );
 270 | };
 271 | 
 272 | export default AIMessage;

```

`staroracle-app_allreact/src/components/AwarenessDetailModal.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { X, Brain, Eye, Heart, MessageCircle } from 'lucide-react';
   4 | import { AwarenessInsight } from '../types/chat';
   5 | 
   6 | interface AwarenessDetailModalProps {
   7 |   isOpen: boolean;
   8 |   onClose: () => void;
   9 |   insight: AwarenessInsight;
  10 |   onAskFollowUp: (question: string) => void;
  11 | }
  12 | 
  13 | const AwarenessDetailModal: React.FC<AwarenessDetailModalProps> = ({
  14 |   isOpen,
  15 |   onClose,
  16 |   insight,
  17 |   onAskFollowUp
  18 | }) => {
  19 |   if (!isOpen) return null;
  20 | 
  21 |   // 获取等级对应的图标和颜色
  22 |   const getLevelConfig = (level: string) => {
  23 |     switch (level) {
  24 |       case 'high':
  25 |         return {
  26 |           icon: Brain,
  27 |           color: 'text-yellow-400',
  28 |           bgColor: 'bg-yellow-400/10',
  29 |           borderColor: 'border-yellow-400/30',
  30 |           title: '深度洞察',
  31 |           description: '这段对话触及了深层的自我认知'
  32 |         };
  33 |       case 'medium':
  34 |         return {
  35 |           icon: Eye,
  36 |           color: 'text-blue-400',
  37 |           bgColor: 'bg-blue-400/10',
  38 |           borderColor: 'border-blue-400/30',
  39 |           title: '中度觉察',
  40 |           description: '这段对话带来了有价值的自我觉察'
  41 |         };
  42 |       case 'low':
  43 |         return {
  44 |           icon: Heart,
  45 |           color: 'text-green-400',
  46 |           bgColor: 'bg-green-400/10',
  47 |           borderColor: 'border-green-400/30',
  48 |           title: '初步觉知',
  49 |           description: '这段对话开启了自我探索的可能'
  50 |         };
  51 |       default:
  52 |         return {
  53 |           icon: MessageCircle,
  54 |           color: 'text-gray-400',
  55 |           bgColor: 'bg-gray-400/10',
  56 |           borderColor: 'border-gray-400/30',
  57 |           title: '一般对话',
  58 |           description: '这是一段常规的对话交流'
  59 |         };
  60 |     }
  61 |   };
  62 | 
  63 |   const levelConfig = getLevelConfig(insight.insightLevel);
  64 |   const LevelIcon = levelConfig.icon;
  65 | 
  66 |   return (
  67 |     <AnimatePresence>
  68 |       {isOpen && (
  69 |         <motion.div
  70 |           initial={{ opacity: 0 }}
  71 |           animate={{ opacity: 1 }}
  72 |           exit={{ opacity: 0 }}
  73 |           className="fixed inset-0 z-50 flex items-center justify-center p-4"
  74 |         >
  75 |           {/* 背景遮罩 */}
  76 |           <motion.div
  77 |             initial={{ opacity: 0 }}
  78 |             animate={{ opacity: 1 }}
  79 |             exit={{ opacity: 0 }}
  80 |             className="absolute inset-0 bg-black/60 backdrop-blur-sm"
  81 |             onClick={onClose}
  82 |           />
  83 |           
  84 |           {/* 弹窗内容 */}
  85 |           <motion.div
  86 |             initial={{ opacity: 0, scale: 0.9, y: 20 }}
  87 |             animate={{ opacity: 1, scale: 1, y: 0 }}
  88 |             exit={{ opacity: 0, scale: 0.9, y: 20 }}
  89 |             className={`
  90 |               relative w-full max-w-md bg-gray-900/95 backdrop-blur-xl 
  91 |               rounded-2xl border ${levelConfig.borderColor} 
  92 |               shadow-2xl overflow-hidden
  93 |             `}
  94 |           >
  95 |             {/* 头部 */}
  96 |             <div className={`${levelConfig.bgColor} px-6 py-4 border-b ${levelConfig.borderColor}`}>
  97 |               <div className="flex items-center justify-between">
  98 |                 <div className="flex items-center space-x-3">
  99 |                   <div className={`
 100 |                     p-2 rounded-full ${levelConfig.bgColor} 
 101 |                     border ${levelConfig.borderColor}
 102 |                   `}>
 103 |                     <LevelIcon className={`w-5 h-5 ${levelConfig.color}`} />
 104 |                   </div>
 105 |                   <div>
 106 |                     <h3 className={`font-semibold ${levelConfig.color} stellar-title`}>
 107 |                       {levelConfig.title}
 108 |                     </h3>
 109 |                     <p className="text-sm text-gray-400 stellar-body">
 110 |                       {levelConfig.description}
 111 |                     </p>
 112 |                   </div>
 113 |                 </div>
 114 |                 <button
 115 |                   onClick={onClose}
 116 |                   className="p-1 rounded-full hover:bg-gray-700/50 transition-colors"
 117 |                 >
 118 |                   <X className="w-5 h-5 text-gray-400" />
 119 |                 </button>
 120 |               </div>
 121 |             </div>
 122 |             
 123 |             {/* 主要内容 */}
 124 |             <div className="p-6 space-y-5">
 125 |               {/* 觉察类型 */}
 126 |               <div>
 127 |                 <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
 128 |                   觉察类型
 129 |                 </h4>
 130 |                 <div className={`
 131 |                   inline-flex items-center px-3 py-1 rounded-full text-xs
 132 |                   ${levelConfig.bgColor} ${levelConfig.borderColor} border
 133 |                   ${levelConfig.color}
 134 |                 `}>
 135 |                   {insight.insightType}
 136 |                 </div>
 137 |               </div>
 138 |               
 139 |               {/* 关键洞察 */}
 140 |               {insight.keyInsights.length > 0 && (
 141 |                 <div>
 142 |                   <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
 143 |                     关键洞察
 144 |                   </h4>
 145 |                   <ul className="space-y-1">
 146 |                     {insight.keyInsights.map((insight, index) => (
 147 |                       <li key={index} className="text-sm text-gray-200 flex items-start stellar-body">
 148 |                         <span className={`inline-block w-1 h-1 rounded-full ${levelConfig.color.replace('text-', 'bg-')} mt-2 mr-2 flex-shrink-0`} />
 149 |                         {insight}
 150 |                       </li>
 151 |                     ))}
 152 |                   </ul>
 153 |                 </div>
 154 |               )}
 155 |               
 156 |               {/* 情绪模式 */}
 157 |               {insight.emotionalPattern && (
 158 |                 <div>
 159 |                   <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
 160 |                     识别模式
 161 |                   </h4>
 162 |                   <p className="text-sm text-gray-200 stellar-body">
 163 |                     {insight.emotionalPattern}
 164 |                   </p>
 165 |                 </div>
 166 |               )}
 167 |               
 168 |               {/* 建议思考 */}
 169 |               {insight.suggestedReflection && (
 170 |                 <div>
 171 |                   <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
 172 |                     深入思考
 173 |                   </h4>
 174 |                   <p className="text-sm text-gray-200 italic stellar-body">
 175 |                     {insight.suggestedReflection}
 176 |                   </p>
 177 |                 </div>
 178 |               )}
 179 |               
 180 |               {/* 后续问题 */}
 181 |               {insight.followUpQuestions.length > 0 && (
 182 |                 <div>
 183 |                   <h4 className="text-sm font-medium text-gray-300 mb-3 stellar-body">
 184 |                     继续探索
 185 |                   </h4>
 186 |                   <div className="space-y-2">
 187 |                     {insight.followUpQuestions.map((question, index) => (
 188 |                       <motion.button
 189 |                         key={index}
 190 |                         whileHover={{ scale: 1.02 }}
 191 |                         whileTap={{ scale: 0.98 }}
 192 |                         onClick={() => {
 193 |                           onAskFollowUp(question);
 194 |                           onClose();
 195 |                         }}
 196 |                         className={`
 197 |                           w-full text-left p-3 rounded-lg border
 198 |                           ${levelConfig.bgColor} ${levelConfig.borderColor}
 199 |                           hover:bg-opacity-20 transition-all duration-200
 200 |                           text-sm text-gray-200 stellar-body
 201 |                         `}
 202 |                       >
 203 |                         <MessageCircle className={`w-4 h-4 ${levelConfig.color} inline mr-2`} />
 204 |                         {question}
 205 |                       </motion.button>
 206 |                     ))}
 207 |                   </div>
 208 |                 </div>
 209 |               )}
 210 |             </div>
 211 |             
 212 |             {/* 底部提示 */}
 213 |             <div className="px-6 py-3 border-t border-gray-700/50 bg-gray-800/30">
 214 |               <p className="text-xs text-gray-400 text-center stellar-body">
 215 |                 点击问题可以继续深入探索
 216 |               </p>
 217 |             </div>
 218 |           </motion.div>
 219 |         </motion.div>
 220 |       )}
 221 |     </AnimatePresence>
 222 |   );
 223 | };
 224 | 
 225 | export default AwarenessDetailModal;

```

`staroracle-app_allreact/src/components/AwarenessIcon.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | 
   4 | interface AwarenessIconProps {
   5 |   level: 'low' | 'medium' | 'high';
   6 |   isActive: boolean; // 是否有觉察价值
   7 |   isAnalyzing: boolean; // 是否正在分析
   8 |   size?: number;
   9 |   onClick?: () => void;
  10 | }
  11 | 
  12 | const AwarenessIcon: React.FC<AwarenessIconProps> = ({ 
  13 |   level, 
  14 |   isActive, 
  15 |   isAnalyzing, 
  16 |   size = 20, 
  17 |   onClick 
  18 | }) => {
  19 |   // 根据觉察等级配置不同的星星效果
  20 |   const getStarConfig = () => {
  21 |     if (!isActive && !isAnalyzing) {
  22 |       return { 
  23 |         color: 'rgba(255,255,255,0.3)', 
  24 |         brightness: 0.3,
  25 |         rayCount: 0,
  26 |         glowIntensity: 0
  27 |       };
  28 |     }
  29 |     
  30 |     switch (level) {
  31 |       case 'high':
  32 |         return { 
  33 |           color: '#FFD700', // 金色超新星
  34 |           brightness: 1,
  35 |           rayCount: 8, // 8条射线
  36 |           glowIntensity: 0.8,
  37 |           starType: 'supernova'
  38 |         };
  39 |       case 'medium':
  40 |         return { 
  41 |           color: '#87CEEB', // 蓝色启明星
  42 |           brightness: 0.8,
  43 |           rayCount: 6, // 6条射线
  44 |           glowIntensity: 0.6,
  45 |           starType: 'bright'
  46 |         };
  47 |       case 'low':
  48 |         return { 
  49 |           color: '#98FB98', // 绿色微光星
  50 |           brightness: 0.6,
  51 |           rayCount: 4, // 4条射线
  52 |           glowIntensity: 0.4,
  53 |           starType: 'dim'
  54 |         };
  55 |       default:
  56 |         return { 
  57 |           color: 'rgba(255,255,255,0.5)', 
  58 |           brightness: 0.5,
  59 |           rayCount: 4,
  60 |           glowIntensity: 0.3
  61 |         };
  62 |     }
  63 |   };
  64 | 
  65 |   const config = getStarConfig();
  66 | 
  67 |   // 分析中的旋转星星动画
  68 |   if (isAnalyzing) {
  69 |     return (
  70 |       <motion.div
  71 |         className="cursor-pointer relative"
  72 |         onClick={onClick}
  73 |         whileHover={{ scale: 1.1 }}
  74 |         whileTap={{ scale: 0.95 }}
  75 |         style={{ width: size, height: size }}
  76 |       >
  77 |         <motion.svg
  78 |           width={size}
  79 |           height={size}
  80 |           viewBox="0 0 24 24"
  81 |           fill="none"
  82 |           animate={{ rotate: [0, 360] }}
  83 |           transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
  84 |         >
  85 |           {/* 中心星核 */}
  86 |           <motion.circle
  87 |             cx="12"
  88 |             cy="12"
  89 |             r="2.5"
  90 |             fill="rgba(138, 95, 189, 0.8)"
  91 |             animate={{
  92 |               scale: [1, 1.2, 1],
  93 |               opacity: [0.8, 1, 0.8]
  94 |             }}
  95 |             transition={{
  96 |               duration: 1.5,
  97 |               repeat: Infinity,
  98 |               ease: "easeInOut"
  99 |             }}
 100 |           />
 101 |           
 102 |           {/* 分析射线 - 渐次出现 */}
 103 |           {[0, 1, 2, 3, 4, 5].map((i) => {
 104 |             const angle = (i * 60) * (Math.PI / 180);
 105 |             const startX = 12 + Math.cos(angle) * 3.5;
 106 |             const startY = 12 + Math.sin(angle) * 3.5;
 107 |             const endX = 12 + Math.cos(angle) * 8;
 108 |             const endY = 12 + Math.sin(angle) * 8;
 109 |             
 110 |             return (
 111 |               <motion.line
 112 |                 key={i}
 113 |                 x1={startX}
 114 |                 y1={startY}
 115 |                 x2={endX}
 116 |                 y2={endY}
 117 |                 stroke="rgba(138, 95, 189, 0.6)"
 118 |                 strokeWidth="1.5"
 119 |                 strokeLinecap="round"
 120 |                 initial={{ pathLength: 0, opacity: 0 }}
 121 |                 animate={{
 122 |                   pathLength: [0, 1, 0],
 123 |                   opacity: [0, 0.8, 0]
 124 |                 }}
 125 |                 transition={{
 126 |                   duration: 2,
 127 |                   repeat: Infinity,
 128 |                   delay: i * 0.2,
 129 |                   ease: "easeInOut"
 130 |                 }}
 131 |               />
 132 |             );
 133 |           })}
 134 |         </motion.svg>
 135 |       </motion.div>
 136 |     );
 137 |   }
 138 | 
 139 |   // 基于觉察等级的星星图标
 140 |   return (
 141 |     <motion.div
 142 |       className="cursor-pointer relative"
 143 |       onClick={onClick}
 144 |       whileHover={{ 
 145 |         scale: isActive ? 1.3 : 1.1,
 146 |         filter: isActive ? `drop-shadow(0 0 8px ${config.color})` : 'none'
 147 |       }}
 148 |       whileTap={{ scale: 0.9 }}
 149 |       style={{ width: size, height: size }}
 150 |       initial={{ opacity: 0, scale: 0.5 }}
 151 |       animate={{ 
 152 |         opacity: isActive ? 1 : 0.4,
 153 |         scale: 1,
 154 |         filter: isActive ? `drop-shadow(0 0 4px ${config.color})` : 'none'
 155 |       }}
 156 |       transition={{ duration: 0.5, ease: "easeOut" }}
 157 |     >
 158 |       <svg
 159 |         width={size}
 160 |         height={size}
 161 |         viewBox="0 0 24 24"
 162 |         fill="none"
 163 |       >
 164 |         {/* 星星核心 */}
 165 |         <motion.circle
 166 |           cx="12"
 167 |           cy="12"
 168 |           r="2.5"
 169 |           fill={config.color}
 170 |           animate={isActive ? {
 171 |             scale: [1, 1.1, 1],
 172 |             opacity: [config.brightness, Math.min(1, config.brightness + 0.2), config.brightness]
 173 |           } : {}}
 174 |           transition={{
 175 |             duration: config.starType === 'supernova' ? 1.5 : 2,
 176 |             repeat: isActive ? Infinity : 0,
 177 |             ease: "easeInOut"
 178 |           }}
 179 |         />
 180 |         
 181 |         {/* 星星射线 - 数量根据等级变化 */}
 182 |         {isActive && config.rayCount > 0 && (
 183 |           <>
 184 |             {Array.from({ length: config.rayCount }, (_, i) => {
 185 |               const angle = (i * (360 / config.rayCount)) * (Math.PI / 180);
 186 |               const startX = 12 + Math.cos(angle) * 3.5;
 187 |               const startY = 12 + Math.sin(angle) * 3.5;
 188 |               const endX = 12 + Math.cos(angle) * (config.starType === 'supernova' ? 9 : 7.5);
 189 |               const endY = 12 + Math.sin(angle) * (config.starType === 'supernova' ? 9 : 7.5);
 190 |               
 191 |               return (
 192 |                 <motion.line
 193 |                   key={i}
 194 |                   x1={startX}
 195 |                   y1={startY}
 196 |                   x2={endX}
 197 |                   y2={endY}
 198 |                   stroke={config.color}
 199 |                   strokeWidth={config.starType === 'supernova' ? "2" : "1.5"}
 200 |                   strokeLinecap="round"
 201 |                   opacity={config.brightness}
 202 |                   initial={{ pathLength: 0, opacity: 0 }}
 203 |                   animate={{
 204 |                     pathLength: [0, 1, 0.8],
 205 |                     opacity: [0, config.brightness, config.brightness * 0.7]
 206 |                   }}
 207 |                   transition={{
 208 |                     duration: config.starType === 'supernova' ? 2 : 2.5,
 209 |                     repeat: Infinity,
 210 |                     delay: i * 0.1,
 211 |                     ease: "easeInOut"
 212 |                   }}
 213 |                 />
 214 |               );
 215 |             })}
 216 |           </>
 217 |         )}
 218 |         
 219 |         {/* 超新星额外效果 - 外圈光环 */}
 220 |         {isActive && config.starType === 'supernova' && (
 221 |           <motion.circle
 222 |             cx="12"
 223 |             cy="12"
 224 |             r="6"
 225 |             stroke={config.color}
 226 |             strokeWidth="0.5"
 227 |             fill="none"
 228 |             opacity="0.4"
 229 |             animate={{
 230 |               scale: [1, 1.2, 1],
 231 |               opacity: [0.4, 0.1, 0.4]
 232 |             }}
 233 |             transition={{
 234 |               duration: 3,
 235 |               repeat: Infinity,
 236 |               ease: "easeInOut"
 237 |             }}
 238 |           />
 239 |         )}
 240 |         
 241 |         {/* 亮星脉冲效果 */}
 242 |         {isActive && config.starType === 'bright' && (
 243 |           <>
 244 |             {[0, 1, 2, 3].map((i) => {
 245 |               const angle = (i * 90) * (Math.PI / 180);
 246 |               const x1 = 12 + Math.cos(angle) * 4;
 247 |               const y1 = 12 + Math.sin(angle) * 4;
 248 |               const x2 = 12 + Math.cos(angle) * 6;
 249 |               const y2 = 12 + Math.sin(angle) * 6;
 250 |               
 251 |               return (
 252 |                 <motion.line
 253 |                   key={`pulse-${i}`}
 254 |                   x1={x1}
 255 |                   y1={y1}
 256 |                   x2={x2}
 257 |                   y2={y2}
 258 |                   stroke={config.color}
 259 |                   strokeWidth="1"
 260 |                   strokeLinecap="round"
 261 |                   opacity="0.6"
 262 |                   animate={{
 263 |                     pathLength: [0, 1, 0],
 264 |                     opacity: [0, 0.6, 0]
 265 |                   }}
 266 |                   transition={{
 267 |                     duration: 2.5,
 268 |                     repeat: Infinity,
 269 |                     delay: i * 0.15 + 1,
 270 |                     ease: "easeInOut"
 271 |                   }}
 272 |                 />
 273 |               );
 274 |             })}
 275 |           </>
 276 |         )}
 277 |       </svg>
 278 |     </motion.div>
 279 |   );
 280 | };
 281 | 
 282 | export default AwarenessIcon;

```

`staroracle-app_allreact/src/components/ChatMessages.tsx`:

```tsx
   1 | import React, { useRef, useEffect } from 'react';
   2 | import { useChatStore } from '../store/useChatStore';
   3 | import UserMessage from './UserMessage';
   4 | import AIMessage from './AIMessage';
   5 | import LoadingMessage from './LoadingMessage';
   6 | 
   7 | // iOS设备检测
   8 | const isIOS = () => {
   9 |   return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
  10 |          (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  11 | };
  12 | 
  13 | interface ChatMessagesProps {
  14 |   onAskFollowUp?: (question: string) => void; // 后续提问回调
  15 | }
  16 | 
  17 | const ChatMessages: React.FC<ChatMessagesProps> = ({ onAskFollowUp }) => {
  18 |   const { messages, isLoading } = useChatStore();
  19 |   const messagesEndRef = useRef<HTMLDivElement>(null);
  20 |   const containerRef = useRef<HTMLDivElement>(null);
  21 | 
  22 |   const scrollToBottom = () => {
  23 |     if (messagesEndRef.current) {
  24 |       // 使用更精确的滚动方式
  25 |       const scrollContainer = messagesEndRef.current.closest('.overflow-y-auto');
  26 |       if (scrollContainer) {
  27 |         scrollContainer.scrollTop = scrollContainer.scrollHeight;
  28 |       } else {
  29 |         messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
  30 |       }
  31 |     }
  32 |   };
  33 | 
  34 |   useEffect(() => {
  35 |     // 延迟滚动，确保DOM更新完成
  36 |     const timer = setTimeout(() => {
  37 |       scrollToBottom();
  38 |     }, 100);
  39 | 
  40 |     return () => clearTimeout(timer);
  41 |   }, [messages, isLoading]);
  42 | 
  43 |   // 根据设备类型计算不同的顶部间距
  44 |   const getTopPadding = () => {
  45 |     if (isIOS()) {
  46 |       // iOS端：较小的间距，因为之前已经有额外的安全区域处理
  47 |       return 'calc(90px + env(safe-area-inset-top, 0px))';
  48 |     } else {
  49 |       // Web端：保持当前的120px间距
  50 |       return 'calc(120px + env(safe-area-inset-top, 0px))';
  51 |     }
  52 |   };
  53 | 
  54 |   // 找到对应的用户问题
  55 |   const getUserQuestionForMessage = (messageIndex: number) => {
  56 |     // 往前查找最近的用户消息
  57 |     for (let i = messageIndex - 1; i >= 0; i--) {
  58 |       if (messages[i].isUser) {
  59 |         return messages[i].text;
  60 |       }
  61 |     }
  62 |     return undefined;
  63 |   };
  64 | 
  65 |   return (
  66 |     <div 
  67 |       className="p-4 space-y-0"
  68 |       style={{
  69 |         paddingTop: getTopPadding(),
  70 |         paddingBottom: '100px' // 避免被底部输入框遮挡
  71 |       }}
  72 |     >
  73 |       {/* 渲染所有消息 */}
  74 |       {messages.map((message, index) => (
  75 |         message.isUser ? (
  76 |           <UserMessage key={message.id} message={message} />
  77 |         ) : (
  78 |           <AIMessage 
  79 |             key={message.id} 
  80 |             message={message}
  81 |             userQuestion={getUserQuestionForMessage(index)}
  82 |             onAskFollowUp={onAskFollowUp}
  83 |           />
  84 |         )
  85 |       ))}
  86 |       
  87 |       {/* 加载状态现在由 AIMessage 组件内部处理 */}
  88 |       
  89 |       {/* 自动滚动锚点 */}
  90 |       <div ref={messagesEndRef} />
  91 |     </div>
  92 |   );
  93 | };
  94 | 
  95 | export default ChatMessages;

```

`staroracle-app_allreact/src/components/ChatOverlay.tsx`:

```tsx
   1 | import React, { useState, useRef, useEffect, useCallback } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { X, Mic } from 'lucide-react';
   4 | import { useChatStore } from '../store/useChatStore';
   5 | import { playSound } from '../utils/soundUtils';
   6 | import { triggerHapticFeedback } from '../utils/hapticUtils';
   7 | import StarRayIcon from './StarRayIcon';
   8 | import ChatMessages from './ChatMessages';
   9 | import FloatingAwarenessPlanet from './FloatingAwarenessPlanet';
  10 | import { Capacitor } from '@capacitor/core';
  11 | import { generateAIResponse } from '../utils/aiTaggingUtils';
  12 | 
  13 | // iOS设备检测
  14 | const isIOS = () => {
  15 |   return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
  16 |          (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  17 | };
  18 | 
  19 | interface ChatOverlayProps {
  20 |   isOpen: boolean;
  21 |   onClose: () => void;
  22 |   onReopen?: () => void; // 新增重新打开的回调
  23 |   followUpQuestion?: string;
  24 |   onFollowUpProcessed?: () => void;
  25 |   initialInput?: string;
  26 |   inputBottomSpace?: number; // 新增：输入框底部空间，用于计算吸附位置
  27 | }
  28 | 
  29 | const ChatOverlay: React.FC<ChatOverlayProps> = ({
  30 |   isOpen,
  31 |   onClose,
  32 |   onReopen,
  33 |   followUpQuestion,
  34 |   onFollowUpProcessed,
  35 |   initialInput,
  36 |   inputBottomSpace = 70 // 默认70px
  37 | }) => {
  38 |   const [isDragging, setIsDragging] = useState(false);
  39 |   const [dragY, setDragY] = useState(0);
  40 |   const [startY, setStartY] = useState(0);
  41 |   
  42 |   // iOS键盘监听和视口调整
  43 |   const [viewportHeight, setViewportHeight] = useState(window.innerHeight);
  44 |   
  45 |   const floatingRef = useRef<HTMLDivElement>(null);
  46 |   const hasProcessedInitialInput = useRef(false);
  47 |   
  48 |   const { 
  49 |     addUserMessage, 
  50 |     addStreamingAIMessage, 
  51 |     updateStreamingMessage, 
  52 |     finalizeStreamingMessage, 
  53 |     setLoading, 
  54 |     isLoading: chatIsLoading, 
  55 |     messages,
  56 |     conversationAwareness,
  57 |     conversationTitle,
  58 |     generateConversationTitle
  59 |   } = useChatStore();
  60 | 
  61 |   // 视口高度监听（仅用于修复iOS浮窗显示问题，不干预键盘行为）
  62 |   useEffect(() => {
  63 |     const handleViewportChange = () => {
  64 |       if (window.visualViewport) {
  65 |         setViewportHeight(window.visualViewport.height);
  66 |       } else {
  67 |         setViewportHeight(window.innerHeight);
  68 |       }
  69 |     };
  70 | 
  71 |     // 监听视口变化 - 仅用于浮窗高度计算
  72 |     if (window.visualViewport) {
  73 |       window.visualViewport.addEventListener('resize', handleViewportChange);
  74 |       return () => {
  75 |         window.visualViewport?.removeEventListener('resize', handleViewportChange);
  76 |       };
  77 |     }
  78 |   }, []);
  79 |   
  80 |   // 计算吸附位置：浮窗顶部 = 输入框底部 - 5px
  81 |   const getAttachedBottomPosition = () => {
  82 |     const gap = 5; // 浮窗顶部与输入框底部的间隙
  83 |     const floatingHeight = 65; // 浮窗关闭时高度65px
  84 |     
  85 |     // 浮窗顶部绝对位置 = 屏幕高度 - (inputBottomSpace - gap)
  86 |     // CSS bottom值 = 浮窗顶部距离屏幕底部的距离 - 浮窗高度
  87 |     // bottom = (inputBottomSpace - gap) - floatingHeight
  88 |     const bottomValue = (inputBottomSpace - gap) - floatingHeight;
  89 |     
  90 |     return bottomValue;
  91 |   };
  92 | 
  93 |   // 获取最后一条消息用于预览
  94 |   const getLastMessagePreview = () => {
  95 |     if (messages.length === 0) return '';
  96 |     const lastMessage = messages[messages.length - 1];
  97 |     const maxLength = 15; // 最大显示长度
  98 |     
  99 |     if (lastMessage.text.length <= maxLength) {
 100 |       return lastMessage.text;
 101 |     }
 102 |     return lastMessage.text.substring(0, maxLength) + '...';
 103 |   };
 104 | 
 105 |   // 处理初始输入文本 - 自动发送初始输入
 106 |   useEffect(() => {
 107 |     if (initialInput && initialInput.trim() && !hasProcessedInitialInput.current) {
 108 |       console.log('🔄 ChatOverlay接收到初始输入:', initialInput);
 109 |       hasProcessedInitialInput.current = true;
 110 |       
 111 |       // 自动发送初始输入
 112 |       setTimeout(() => {
 113 |         sendMessage(initialInput);
 114 |       }, 300);
 115 |     }
 116 |   }, [initialInput]);
 117 | 
 118 |   // 重置标记当组件关闭时
 119 |   useEffect(() => {
 120 |     if (!isOpen) {
 121 |       hasProcessedInitialInput.current = false;
 122 |       setDragY(0);
 123 |     }
 124 |   }, [isOpen]);
 125 | 
 126 |   // 处理外部传入的后续问题
 127 |   useEffect(() => {
 128 |     if (followUpQuestion && followUpQuestion.trim()) {
 129 |       console.log('🔄 ChatOverlay接收到后续问题:', followUpQuestion);
 130 |       setTimeout(() => {
 131 |         sendMessage(followUpQuestion);
 132 |         if (onFollowUpProcessed) {
 133 |           onFollowUpProcessed();
 134 |         }
 135 |       }, 200);
 136 |     }
 137 |   }, [followUpQuestion, onFollowUpProcessed]);
 138 | 
 139 |   // 拖拽处理逻辑 - 优化为全局拖拽检测
 140 |   const handleTouchStart = (e: React.TouchEvent) => {
 141 |     if (!isOpen) return;
 142 |     
 143 |     setIsDragging(true);
 144 |     setStartY(e.touches[0].clientY);
 145 |     
 146 |     // 检查对话滚动容器是否已滚动到顶部
 147 |     const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto');
 148 |     const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1; // 1px容差
 149 |     
 150 |     console.log('🖱️ 开始拖拽，对话是否在顶部:', isAtTop);
 151 |   };
 152 | 
 153 |   const handleTouchMove = (e: React.TouchEvent) => {
 154 |     if (!isDragging || !isOpen) return;
 155 |     
 156 |     const currentY = e.touches[0].clientY;
 157 |     const deltaY = currentY - startY;
 158 |     
 159 |     // 先检查是否是微小下拉动作（优先级最高）
 160 |     if (deltaY > 0 && deltaY <= 20) {
 161 |       console.log(`📱 检测到微小下拉: ${deltaY}px，在整个浮窗范围内允许收起`);
 162 |       setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 163 |       return;
 164 |     }
 165 |     
 166 |     // 检查对话滚动容器的状态
 167 |     const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto') as HTMLElement;
 168 |     const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1; // 1px容差
 169 |     
 170 |     // 大于20px的下拉动作才需要考虑滚动状态
 171 |     if (deltaY > 20) {
 172 |       // 情况1：在头部拖拽区域 - 始终允许拖拽
 173 |       const target = (e.target as HTMLElement).closest('.drag-handle');
 174 |       if (target) {
 175 |         console.log('📱 在头部拖拽区域，允许拖拽');
 176 |         setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 177 |         return;
 178 |       }
 179 |       
 180 |       // 情况2：对话区域已滚动到顶部 - 允许拖拽收起浮窗
 181 |       if (isAtTop) {
 182 |         console.log('📱 对话在顶部，允许拖拽浮窗');
 183 |         setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 184 |         return;
 185 |       }
 186 |       
 187 |       // 情况3：对话区域还有内容可滚动且下拉距离较大 - 让对话自由滚动
 188 |       console.log('📱 对话还可滚动，不处理浮窗拖拽');
 189 |     }
 190 |   };
 191 | 
 192 |   const handleTouchEnd = () => {
 193 |     if (!isDragging) return;
 194 |     setIsDragging(false);
 195 |     
 196 |     console.log(`📱 手指抬起，当前dragY: ${dragY}px`);
 197 |     
 198 |     // 微小拖拽更敏感的阈值 - 只要5px就能关闭浮窗
 199 |     if (dragY > 5) { 
 200 |       console.log('🔽 拖拽距离足够，关闭浮窗');
 201 |       onClose();
 202 |     } else {
 203 |       // 否则回弹到原位置
 204 |       console.log('↩️ 拖拽距离不够，回弹');
 205 |       setDragY(0);
 206 |     }
 207 |   };
 208 | 
 209 |   // 鼠标事件处理（用于桌面端调试）- 保持与触摸事件一致
 210 |   const handleMouseDown = (e: React.MouseEvent) => {
 211 |     if (!isOpen) return;
 212 |     
 213 |     setIsDragging(true);
 214 |     setStartY(e.clientY);
 215 |   };
 216 | 
 217 |   const handleMouseMove = (e: MouseEvent) => {
 218 |     if (!isDragging || !isOpen) return;
 219 |     
 220 |     const currentY = e.clientY;
 221 |     const deltaY = currentY - startY;
 222 |     
 223 |     // 先检查是否是微小下拉动作（优先级最高）
 224 |     if (deltaY > 0 && deltaY <= 20) {
 225 |       console.log(`📱 检测到微小下拉: ${deltaY}px，在整个浮窗范围内允许收起`);
 226 |       setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 227 |       return;
 228 |     }
 229 |     
 230 |     // 检查对话滚动容器的状态
 231 |     const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto') as HTMLElement;
 232 |     const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1;
 233 |     
 234 |     if (deltaY > 20) {
 235 |       // 情况1：在头部拖拽区域 - 始终允许拖拽
 236 |       const target = (e.target as HTMLElement).closest('.drag-handle');
 237 |       if (target) {
 238 |         setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 239 |         return;
 240 |       }
 241 |       
 242 |       // 情况2：对话区域已滚动到顶部 - 继续下拉直接收起浮窗
 243 |       if (isAtTop) {
 244 |         setDragY(Math.min(deltaY, window.innerHeight * 0.8));
 245 |         return;
 246 |       }
 247 |     }
 248 |   };
 249 | 
 250 |   const handleMouseUp = () => {
 251 |     if (!isDragging) return;
 252 |     setIsDragging(false);
 253 |     
 254 |     console.log(`📱 鼠标抬起，当前dragY: ${dragY}px`);
 255 |     
 256 |     // 使用相同的敏感阈值
 257 |     if (dragY > 5) {
 258 |       console.log('🔽 拖拽距离足够，关闭浮窗');
 259 |       onClose();
 260 |     } else {
 261 |       console.log('↩️ 拖拽距离不够，回弹');
 262 |       setDragY(0);
 263 |     }
 264 |   };
 265 | 
 266 |   // 添加全局鼠标事件监听
 267 |   useEffect(() => {
 268 |     if (isDragging) {
 269 |       document.addEventListener('mousemove', handleMouseMove);
 270 |       document.addEventListener('mouseup', handleMouseUp);
 271 |       
 272 |       return () => {
 273 |         document.removeEventListener('mousemove', handleMouseMove);
 274 |         document.removeEventListener('mouseup', handleMouseUp);
 275 |       };
 276 |     }
 277 |   }, [isDragging, startY, dragY]);
 278 | 
 279 |   // 发送消息的核心逻辑（带重试机制）
 280 |   const sendMessage = async (messageText: string, retryCount = 0) => {
 281 |     if (!messageText.trim() || chatIsLoading) return;
 282 |     
 283 |     const trimmedQuestion = messageText.trim();
 284 |     const maxRetries = 3; // 最大重试次数
 285 |     
 286 |     // 只在第一次尝试时添加用户消息
 287 |     if (retryCount === 0) {
 288 |       addUserMessage(trimmedQuestion);
 289 |       playSound('starClick');
 290 |     }
 291 |     
 292 |     setLoading(true);
 293 |     
 294 |     try {
 295 |       console.log(`🤖 开始生成AI回复... (尝试 ${retryCount + 1}/${maxRetries + 1})`);
 296 |       
 297 |       const messageId = addStreamingAIMessage('');
 298 |       let streamingText = '';
 299 |       
 300 |       const onStream = (chunk: string) => {
 301 |         streamingText += chunk;
 302 |         updateStreamingMessage(messageId, streamingText);
 303 |       };
 304 |       
 305 |       const conversationHistory = messages.map(msg => ({
 306 |         role: msg.isUser ? 'user' as const : 'assistant' as const,
 307 |         content: msg.text
 308 |       }));
 309 |       
 310 |       console.log('📚 Conversation history:', conversationHistory.length, 'messages');
 311 |       
 312 |       const aiResponse = await generateAIResponse(
 313 |         trimmedQuestion, 
 314 |         undefined, 
 315 |         onStream, 
 316 |         conversationHistory
 317 |       );
 318 |       
 319 |       if (streamingText !== aiResponse) {
 320 |         updateStreamingMessage(messageId, aiResponse);
 321 |       }
 322 |       
 323 |       finalizeStreamingMessage(messageId);
 324 |       setLoading(false);
 325 |       playSound('starReveal');
 326 |       
 327 |       console.log('✅ AI回复生成成功:', aiResponse);
 328 |       
 329 |       // 在第一次AI回复后，尝试生成对话标题
 330 |       setTimeout(() => {
 331 |         generateConversationTitle();
 332 |       }, 1000);
 333 |       
 334 |     } catch (error) {
 335 |       console.error(`❌ AI回复生成失败 (尝试 ${retryCount + 1}/${maxRetries + 1}):`, error);
 336 |       
 337 |       if (retryCount < maxRetries) {
 338 |         // 还有重试机会，等待后重试
 339 |         console.log(`🔄 将在2秒后重试...`);
 340 |         setTimeout(() => {
 341 |           sendMessage(messageText, retryCount + 1);
 342 |         }, 2000);
 343 |       } else {
 344 |         // 重试次数用完，直接结束加载状态
 345 |         console.error('❌ 重试次数用完，AI回复失败');
 346 |         setLoading(false);
 347 |         
 348 |         // 移除可能创建的空消息
 349 |         const lastMessage = messages[messages.length - 1];
 350 |         if (lastMessage && !lastMessage.isUser && !lastMessage.text.trim()) {
 351 |           // 这里可以选择移除空消息，或者什么都不做
 352 |           console.log('🗑️ 移除空的AI消息');
 353 |         }
 354 |       }
 355 |     }
 356 |   };
 357 | 
 358 |   const handleFollowUpQuestion = (question: string) => {
 359 |     console.log('📱 ChatOverlay层接收到后续提问:', question);
 360 |     sendMessage(question);
 361 |   };
 362 | 
 363 |   return (
 364 |     <>
 365 |       {/* 遮罩层 - 只在完全展开时显示 */}
 366 |       <div 
 367 |         className={`fixed inset-0 bg-black transition-opacity duration-300 ${
 368 |           isOpen ? 'bg-opacity-40 pointer-events-auto z-45' : 'bg-opacity-0 pointer-events-none z-10'
 369 |         }`}
 370 |         onClick={isOpen ? onClose : undefined}
 371 |       />
 372 | 
 373 |       {/* 浮窗内容 - 关闭时吸附在底部，展开时全屏 */}
 374 |       <motion.div 
 375 |         ref={floatingRef}
 376 |         className={`fixed shadow-2xl z-45 bg-gray-900 ${!isOpen ? 'cursor-pointer' : ''} ${
 377 |           isOpen ? 'rounded-t-2xl' : 'rounded-full'
 378 |         }`}
 379 |         initial={false}
 380 |         animate={{          
 381 |           // 修复动画：使用一致的定位方式
 382 |           top: isOpen ? Math.max(80, 80 + dragY) : window.innerHeight - getAttachedBottomPosition() - 65,
 383 |           left: isOpen ? 0 : '50%',
 384 |           right: isOpen ? 0 : 'auto',
 385 |           // 移除bottom定位，只使用top定位
 386 |           width: isOpen ? '100vw' : 'min(28rem, calc(100vw - 2rem))',
 387 |           // 修复iOS键盘问题：使用实际视口高度
 388 |           height: isOpen ? `${viewportHeight - Math.max(80, 80 + dragY)}px` : 65,
 389 |           x: isOpen ? 0 : '-50%',
 390 |           y: dragY * 0.15,
 391 |           opacity: Math.max(0.9, 1 - dragY / 500)
 392 |         }}
 393 |         transition={{
 394 |           type: 'spring',
 395 |           damping: 25,
 396 |           stiffness: 300,
 397 |           duration: 0.3
 398 |         }}
 399 |         style={{
 400 |           pointerEvents: 'auto'
 401 |         }}
 402 |         onTouchStart={isOpen ? handleTouchStart : undefined}
 403 |         onTouchMove={isOpen ? handleTouchMove : undefined}
 404 |         onTouchEnd={isOpen ? handleTouchEnd : undefined}
 405 |         onMouseDown={isOpen ? handleMouseDown : undefined}
 406 |       >
 407 |         {/* 浮窗内容：关闭时显示简洁的吸附状态，展开时显示完整内容 */}
 408 |         {!isOpen && (
 409 |           <div 
 410 |             className="relative w-full h-full cursor-pointer"
 411 |             onClick={(e) => {
 412 |               // 点击浮窗任意位置都弹出（除了按钮）
 413 |               e.stopPropagation();
 414 |               console.log('🔄 点击收缩的浮窗，重新展开');
 415 |               if (onReopen) {
 416 |                 onReopen();
 417 |               }
 418 |             }}
 419 |           >
 420 |             {/* 精确定位的控制栏 - 距离浮窗上边缘6px */}
 421 |             <div 
 422 |               className="absolute left-0 right-0 flex items-center justify-between px-4"
 423 |               style={{ top: '6px' }}
 424 |             >
 425 |               {/* 左侧：完成按钮 */}
 426 |               <div className="flex-1 text-left">
 427 |                 <button
 428 |                   onClick={(e) => {
 429 |                     e.stopPropagation(); // 阻止冒泡到父元素的展开事件
 430 |                     onClose();
 431 |                   }}
 432 |                   className="px-3 py-1 rounded-full dialog-transparent-button transition-colors duration-200 text-blue-400 text-sm font-medium stellar-body"
 433 |                 >
 434 |                   完成
 435 |                 </button>
 436 |               </div>
 437 |               
 438 |               {/* 中间：当前对话标题 */}
 439 |               <div className="flex-1 flex justify-center">
 440 |                 <span className="text-gray-400 text-sm font-medium stellar-body">
 441 |                   当前对话
 442 |                 </span>
 443 |               </div>
 444 |               
 445 |               {/* 右侧：关闭按钮 */}
 446 |               <div className="flex-1 flex justify-end">
 447 |                 <button
 448 |                   onClick={(e) => {
 449 |                     e.stopPropagation(); // 阻止冒泡到父元素的展开事件
 450 |                     onClose();
 451 |                   }}
 452 |                   className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
 453 |                 >
 454 |                   <X className="w-4 h-4" strokeWidth={2} />
 455 |                 </button>
 456 |               </div>
 457 |             </div>
 458 |           </div>
 459 |         )}
 460 | 
 461 |         {/* 展开状态的正常内容 */}
 462 |         {isOpen && (
 463 |           <>
 464 |             {/* 拖拽指示器和头部 */}
 465 |             <div className="drag-handle cursor-grab active:cursor-grabbing">
 466 |               <div className="flex justify-center py-4">
 467 |                 <div className="w-12 h-1.5 bg-gray-600 rounded-full"></div>
 468 |               </div>
 469 |               
 470 |               <div className="px-4 pb-4">
 471 |                 <div className="flex items-center justify-between">
 472 |                   {conversationTitle && (
 473 |                     <h1 className="stellar-title text-white">
 474 |                       {conversationTitle}
 475 |                     </h1>
 476 |                   )}
 477 |                   <button
 478 |                     onClick={onClose}
 479 |                     className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
 480 |                       !conversationTitle ? 'ml-auto' : ''
 481 |                     }`}
 482 |                   >
 483 |                     <X className="w-5 h-5" />
 484 |                   </button>
 485 |                 </div>
 486 |               </div>
 487 |             </div>
 488 | 
 489 |             {/* 浮窗对话区域 - 只在展开时显示 */}
 490 |             <div className="flex-1 flex flex-col" style={{ height: 'calc(100% - 140px)' }}>
 491 |               {/* 消息列表 - 允许滚动 */}
 492 |               <div 
 493 |                 className="flex-1 overflow-y-auto scrollbar-hidden"
 494 |                 style={{
 495 |                   WebkitOverflowScrolling: 'touch', // iOS平滑滚动
 496 |                   overscrollBehavior: 'contain', // 防止滚动传播
 497 |                 }}
 498 |               >
 499 |                 <ChatMessages onAskFollowUp={handleFollowUpQuestion} />
 500 |               </div>
 501 | 
 502 |               {/* 底部留空，让主界面的输入框显示在这里 */}
 503 |               <div className="h-20"></div>
 504 |             </div>
 505 |           </>
 506 |         )}
 507 |       </motion.div>
 508 |     </>
 509 |   );
 510 | };
 511 | 
 512 | export default ChatOverlay;

```

`staroracle-app_allreact/src/components/CollectionButton.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | import { BookOpen, Star } from 'lucide-react';
   4 | import { useStarStore } from '../store/useStarStore';
   5 | 
   6 | interface CollectionButtonProps {
   7 |   onClick: () => void;
   8 | }
   9 | 
  10 | const CollectionButton: React.FC<CollectionButtonProps> = ({ onClick }) => {
  11 |   const { constellation } = useStarStore();
  12 |   const starCount = constellation.stars.length;
  13 | 
  14 |   const handleClick = () => {
  15 |     console.log('🔍 CollectionButton internal click triggered!');
  16 |     onClick();
  17 |   };
  18 | 
  19 |   return (
  20 |     <motion.button
  21 |       className="collection-trigger-btn"
  22 |       onClick={handleClick}
  23 |       whileHover={{ scale: 1.05 }}
  24 |       whileTap={{ scale: 0.95 }}
  25 |       initial={{ opacity: 0, x: -20 }}
  26 |       animate={{ opacity: 1, x: 0 }}
  27 |       transition={{ delay: 0.5 }}
  28 |     >
  29 |       <div className="btn-content">
  30 |         <div className="btn-icon">
  31 |           <BookOpen className="w-5 h-5" />
  32 |           {starCount > 0 && (
  33 |             <motion.div
  34 |               className="star-count-badge"
  35 |               initial={{ scale: 0 }}
  36 |               animate={{ scale: 1 }}
  37 |               key={starCount}
  38 |             >
  39 |               {starCount}
  40 |             </motion.div>
  41 |           )}
  42 |         </div>
  43 |         <span className="btn-text">Star Collection</span>
  44 |       </div>
  45 |       
  46 |       {/* Floating stars animation */}
  47 |       <div className="floating-stars">
  48 |         {Array.from({ length: 3 }).map((_, i) => (
  49 |           <motion.div
  50 |             key={i}
  51 |             className="floating-star"
  52 |             animate={{
  53 |               y: [-5, -15, -5],
  54 |               opacity: [0.3, 0.8, 0.3],
  55 |               scale: [0.8, 1.2, 0.8],
  56 |             }}
  57 |             transition={{
  58 |               duration: 2,
  59 |               repeat: Infinity,
  60 |               delay: i * 0.3,
  61 |             }}
  62 |           >
  63 |             <Star className="w-3 h-3" />
  64 |           </motion.div>
  65 |         ))}
  66 |       </div>
  67 |     </motion.button>
  68 |   );
  69 | };
  70 | 
  71 | export default CollectionButton;

```

`staroracle-app_allreact/src/components/Constellation.tsx`:

```tsx
   1 | import React, { useEffect, useState, useCallback } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { useStarStore } from '../store/useStarStore';
   4 | import { useChatStore } from '../store/useChatStore'; // 添加聊天状态导入
   5 | import { playSound } from '../utils/soundUtils';
   6 | import Star from './Star';
   7 | import StarRayIcon from './StarRayIcon';
   8 | 
   9 | const Constellation: React.FC = () => {
  10 |   const { 
  11 |     constellation, 
  12 |     activeStarId, 
  13 |     viewStar, 
  14 |     setIsAsking,
  15 |     drawInspirationCard,
  16 |     pendingStarPosition,
  17 |     isLoading
  18 |   } = useStarStore();
  19 |   
  20 |   // 添加聊天状态检查
  21 |   const { messages, isLoading: chatIsLoading } = useChatStore();
  22 |   
  23 |   const { stars, connections } = constellation;
  24 |   const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  25 |   const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  26 |   const [sparkles, setSparkles] = useState<Array<{ id: number; x: number; y: number }>>([]);
  27 |   const [lastClickTime, setLastClickTime] = useState(0);
  28 |   
  29 |   useEffect(() => {
  30 |     const updateDimensions = () => {
  31 |       setDimensions({
  32 |         width: window.innerWidth,
  33 |         height: window.innerHeight,
  34 |       });
  35 |     };
  36 |     
  37 |     window.addEventListener('resize', updateDimensions);
  38 |     updateDimensions();
  39 |     
  40 |     return () => window.removeEventListener('resize', updateDimensions);
  41 |   }, []);
  42 |   
  43 |   const handleMouseMove = useCallback((e: React.MouseEvent) => {
  44 |     setMousePos({ x: e.clientX, y: e.clientY });
  45 |   }, []);
  46 |   
  47 |   const handleStarClick = (id: string) => {
  48 |     playSound('starClick');
  49 |     viewStar(id);
  50 |   };
  51 |   
  52 |   const createSparkle = (x: number, y: number) => {
  53 |     const id = Date.now();
  54 |     setSparkles(current => [...current, { id, x, y }]);
  55 |     setTimeout(() => {
  56 |       setSparkles(current => current.filter(sparkle => sparkle.id !== id));
  57 |     }, 1000);
  58 |   };
  59 |   
  60 |   const handleBackgroundClick = (e: React.MouseEvent) => {
  61 |     console.log('🌌 Constellation clicked at:', e.clientX, e.clientY);
  62 |     console.log('🎯 Click target:', e.target);
  63 |     
  64 |     // 检查是否有活跃的聊天会话
  65 |     const hasActiveChat = messages.length > 0 || chatIsLoading;
  66 |     if (hasActiveChat) {
  67 |       console.log('💬 聊天会话活跃中，跳过灵感卡片显示');
  68 |       return; // 有聊天记录时不显示灵感卡片
  69 |     }
  70 |     
  71 |     // 检查点击是否在按钮区域 - 排除左上角和右上角按钮区域
  72 |     const isInButtonArea = (clientX: number, clientY: number) => {
  73 |       // 左侧按钮区域 (Collection + Template)
  74 |       if (clientX < 200 && clientY < 200) return true;
  75 |       // 右侧按钮区域 (Settings)  
  76 |       if (clientX > window.innerWidth - 200 && clientY < 200) return true;
  77 |       return false;
  78 |     };
  79 |     
  80 |     if (isInButtonArea(e.clientX, e.clientY)) {
  81 |       console.log('🚫 Click in button area, ignoring');
  82 |       return; // 不处理按钮区域的点击
  83 |     }
  84 |     
  85 |     // If we're currently loading a star, don't allow new interactions
  86 |     if (isLoading) return;
  87 |     
  88 |     if ((e.target as HTMLElement).classList.contains('constellation-area')) {
  89 |       console.log('✅ Valid constellation area click');
  90 |       const currentTime = Date.now();
  91 |       const timeDiff = currentTime - lastClickTime;
  92 |       
  93 |       const rect = (e.target as HTMLElement).getBoundingClientRect();
  94 |       const x = ((e.clientX - rect.left) / rect.width) * 100;
  95 |       const y = ((e.clientY - rect.top) / rect.height) * 100;
  96 |       
  97 |       createSparkle(e.clientX, e.clientY);
  98 |       playSound('starReveal'); // 改为使用右键的音效
  99 |       
 100 |       // 移动端单击直接走右键链路 - 弹出灵感卡片
 101 |       console.log('🌟 主屏幕点击 - 显示灵感卡片（复用右键逻辑）');
 102 |       const card = drawInspirationCard();
 103 |       console.log('📇 灵感卡片已生成:', card.question);
 104 |       
 105 |       setLastClickTime(currentTime);
 106 |     } else {
 107 |       console.log('❌ Click not on constellation area');
 108 |     }
 109 |   };
 110 |   
 111 |   // 右键点击事件处理 - 显示灵感卡片
 112 |   const handleContextMenu = (e: React.MouseEvent) => {
 113 |     // If we're currently loading a star, don't allow new interactions
 114 |     if (isLoading) return;
 115 |     
 116 |     // 检查是否有活跃的聊天会话
 117 |     const hasActiveChat = messages.length > 0 || chatIsLoading;
 118 |     if (hasActiveChat) {
 119 |       console.log('💬 聊天会话活跃中，跳过灵感卡片显示（右键）');
 120 |       return; // 有聊天记录时不显示灵感卡片
 121 |     }
 122 |     
 123 |     e.preventDefault(); // 阻止默认的右键菜单
 124 |     console.log('🔍 右键点击事件触发');
 125 |     
 126 |     if ((e.target as HTMLElement).classList.contains('constellation-area')) {
 127 |       const rect = (e.target as HTMLElement).getBoundingClientRect();
 128 |       const x = ((e.clientX - rect.left) / rect.width) * 100;
 129 |       const y = ((e.clientY - rect.top) / rect.height) * 100;
 130 |       
 131 |       createSparkle(e.clientX, e.clientY);
 132 |       playSound('starReveal');
 133 |       
 134 |       console.log('🌟 右键点击 - 显示灵感卡片');
 135 |       const card = drawInspirationCard();
 136 |       console.log('📇 灵感卡片已生成:', card.question);
 137 |     }
 138 |   };
 139 |   
 140 |   return (
 141 |     <div 
 142 |       className="absolute inset-0 overflow-hidden constellation-area"
 143 |       onClick={handleBackgroundClick}
 144 |       onContextMenu={handleContextMenu}
 145 |       onMouseMove={handleMouseMove}
 146 |     >
 147 |       {/* Hover indicator */}
 148 |       <div 
 149 |         className="hover-indicator"
 150 |         style={{
 151 |           left: `${mousePos.x}px`,
 152 |           top: `${mousePos.y}px`,
 153 |         }}
 154 |       />
 155 |       
 156 |       {/* Loading animation for pending star */}
 157 |       {isLoading && pendingStarPosition && (
 158 |         <div 
 159 |           className="absolute pointer-events-none z-20"
 160 |           style={{
 161 |             left: `${pendingStarPosition.x}%`,
 162 |             top: `${pendingStarPosition.y}%`,
 163 |             transform: 'translate(-50%, -50%)'
 164 |           }}
 165 |         >
 166 |           <motion.div
 167 |             initial={{ scale: 0, opacity: 0 }}
 168 |             animate={{ 
 169 |               scale: [0.8, 1.2, 0.8],
 170 |               opacity: [0.4, 0.8, 0.4]
 171 |             }}
 172 |             transition={{
 173 |               duration: 2,
 174 |               repeat: Infinity,
 175 |               ease: "easeInOut"
 176 |             }}
 177 |             className="flex items-center justify-center"
 178 |           >
 179 |             <StarRayIcon size={48} animated={true} className="text-cosmic-accent" />
 180 |           </motion.div>
 181 |         </div>
 182 |       )}
 183 |       
 184 |       {/* Sparkle effects */}
 185 |       <AnimatePresence>
 186 |         {sparkles.map(sparkle => (
 187 |           <motion.div
 188 |             key={sparkle.id}
 189 |             className="star-sparkle"
 190 |             style={{
 191 |               left: sparkle.x - 10,
 192 |               top: sparkle.y - 10,
 193 |             }}
 194 |             initial={{ scale: 0, rotate: 0, opacity: 0 }}
 195 |             animate={{ scale: 1, rotate: 180, opacity: 1 }}
 196 |             exit={{ scale: 0, rotate: 360, opacity: 0 }}
 197 |           />
 198 |         ))}
 199 |       </AnimatePresence>
 200 |       
 201 |       {/* Star connections - 使用绝对定位的SVG，确保与星星在同一坐标系统 */}
 202 |       {dimensions.width > 0 && dimensions.height > 0 && (
 203 |         <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 5, overflow: 'visible' }}>
 204 |         <svg
 205 |           width={dimensions.width}
 206 |           height={dimensions.height}
 207 |             style={{ 
 208 |               position: 'absolute', 
 209 |               top: 0, 
 210 |               left: 0,
 211 |               overflow: 'visible'
 212 |             }}
 213 |         >
 214 |           <defs>
 215 |               {connections.map(connection => {
 216 |                 const fromStar = stars.find(s => s.id === connection.fromStarId);
 217 |                 const toStar = stars.find(s => s.id === connection.toStarId);
 218 |                 
 219 |                 if (!fromStar || !toStar) return null;
 220 |                 
 221 |                 // 根据连线标签选择颜色
 222 |                 const baseColor = (() => {
 223 |                   // If the connection belongs to a specific constellation (tag-based), use that tag to determine color
 224 |                   if (connection.constellationName) {
 225 |                     const tag = connection.constellationName.toLowerCase();
 226 |                     
 227 |                     // Core Life Areas
 228 |                     if (['love', 'romance', 'heart', 'relationship', 'intimacy'].includes(tag)) {
 229 |                       return '255, 105, 180'; // Hot Pink
 230 |                     }
 231 |                     if (['family', 'parents', 'children', 'home', 'roots'].includes(tag)) {
 232 |                       return '255, 165, 0'; // Orange
 233 |                     }
 234 |                     if (['friendship', 'social', 'trust', 'loyalty'].includes(tag)) {
 235 |                       return '124, 252, 0'; // Lawn Green
 236 |                     }
 237 |                     if (['career', 'work', 'profession', 'vocation'].includes(tag)) {
 238 |                       return '255, 215, 0'; // Gold
 239 |                     }
 240 |                     if (['education', 'learning', 'knowledge', 'skills'].includes(tag)) {
 241 |                       return '30, 144, 255'; // Dodger Blue
 242 |                     }
 243 |                     if (['health', 'wellness', 'fitness', 'balance'].includes(tag)) {
 244 |                       return '50, 205, 50'; // Lime Green
 245 |                     }
 246 |                     if (['finance', 'money', 'wealth', 'abundance'].includes(tag)) {
 247 |                       return '218, 165, 32'; // Golden Rod
 248 |                     }
 249 |                     if (['spirituality', 'faith', 'soul', 'divine'].includes(tag)) {
 250 |                       return '147, 112, 219'; // Medium Purple
 251 |                     }
 252 |                     
 253 |                     // Inner Experience
 254 |                     if (['emotions', 'feelings', 'expression', 'awareness'].includes(tag)) {
 255 |                       return '255, 99, 71'; // Tomato
 256 |                     }
 257 |                     if (['happiness', 'joy', 'fulfillment', 'contentment'].includes(tag)) {
 258 |                       return '255, 255, 0'; // Yellow
 259 |                     }
 260 |                     if (['anxiety', 'fear', 'worry', 'stress'].includes(tag)) {
 261 |                       return '70, 130, 180'; // Steel Blue
 262 |                     }
 263 |                     if (['grief', 'loss', 'sadness', 'mourning'].includes(tag)) {
 264 |                       return '75, 0, 130'; // Indigo
 265 |                     }
 266 |                     
 267 |                     // Self Development
 268 |                     if (['identity', 'self', 'authenticity', 'values'].includes(tag)) {
 269 |                       return '0, 206, 209'; // Dark Turquoise
 270 |                     }
 271 |                     if (['purpose', 'meaning', 'calling', 'mission'].includes(tag)) {
 272 |                       return '138, 43, 226'; // Blue Violet
 273 |                     }
 274 |                     if (['growth', 'development', 'evolution', 'improvement'].includes(tag)) {
 275 |                       return '60, 179, 113'; // Medium Sea Green
 276 |                     }
 277 |                     if (['resilience', 'strength', 'adaptation', 'recovery'].includes(tag)) {
 278 |                       return '178, 34, 34'; // Firebrick
 279 |                     }
 280 |                     if (['creativity', 'expression', 'imagination', 'innovation'].includes(tag)) {
 281 |                       return '255, 140, 0'; // Dark Orange
 282 |                     }
 283 |                     if (['wisdom', 'insight', 'perspective', 'understanding'].includes(tag)) {
 284 |                       return '186, 85, 211'; // Medium Orchid
 285 |                     }
 286 |                     
 287 |                     // Default colors for other tags
 288 |                     if (['mindfulness', 'presence', 'awareness'].includes(tag)) {
 289 |                       return '240, 230, 140'; // Khaki
 290 |                     }
 291 |                     if (['change', 'transition', 'transformation'].includes(tag)) {
 292 |                       return '0, 191, 255'; // Deep Sky Blue
 293 |                     }
 294 |                     
 295 |                     // If no specific match, use a hash-based color to ensure consistent colors for same tag
 296 |                     const hash = tag.split('').reduce((acc, char) => {
 297 |                       return acc + char.charCodeAt(0);
 298 |                     }, 0);
 299 |                     
 300 |                     // Generate a pastel color based on the hash
 301 |                     const h = hash % 360;
 302 |                     const s = 70 + (hash % 20); // 70-90%
 303 |                     const l = 65 + (hash % 15); // 65-80%
 304 |                     
 305 |                     // Convert HSL to RGB
 306 |                     const c = (1 - Math.abs(2 * l / 100 - 1)) * s / 100;
 307 |                     const x = c * (1 - Math.abs((h / 60) % 2 - 1));
 308 |                     const m = l / 100 - c / 2;
 309 |                     
 310 |                     let r, g, b;
 311 |                     if (h < 60) { r = c; g = x; b = 0; }
 312 |                     else if (h < 120) { r = x; g = c; b = 0; }
 313 |                     else if (h < 180) { r = 0; g = c; b = x; }
 314 |                     else if (h < 240) { r = 0; g = x; b = c; }
 315 |                     else if (h < 300) { r = x; g = 0; b = c; }
 316 |                     else { r = c; g = 0; b = x; }
 317 |                     
 318 |                     r = Math.round((r + m) * 255);
 319 |                     g = Math.round((g + m) * 255);
 320 |                     b = Math.round((b + m) * 255);
 321 |                     
 322 |                     return `${r}, ${g}, ${b}`;
 323 |                   }
 324 |                   
 325 |                   // Fall back to original logic for connections not based on specific constellation
 326 |                   if (connection.sharedTags?.includes('love') || connection.sharedTags?.includes('romance')) {
 327 |                     return '255, 182, 193'; // 粉色
 328 |                   }
 329 |                   if (connection.sharedTags?.includes('wisdom') || connection.sharedTags?.includes('purpose')) {
 330 |                     return '138, 95, 189'; // 紫色
 331 |                   }
 332 |                   if (connection.sharedTags?.includes('success') || connection.sharedTags?.includes('career')) {
 333 |                     return '255, 215, 0'; // 金色
 334 |                   }
 335 |                   return '255, 255, 255'; // 白色
 336 |                 })();
 337 |                 
 338 |                 // 计算星星中心的像素坐标
 339 |                 const fromX = (fromStar.x / 100) * dimensions.width;
 340 |                 const fromY = (fromStar.y / 100) * dimensions.height;
 341 |                 const toX = (toStar.x / 100) * dimensions.width;
 342 |                 const toY = (toStar.y / 100) * dimensions.height;
 343 |               
 344 |               return (
 345 |                   <linearGradient
 346 |                     key={connection.id}
 347 |                     id={`gradient-${connection.id}`}
 348 |                     gradientUnits="userSpaceOnUse"
 349 |                     x1={fromX}
 350 |                     y1={fromY}
 351 |                     x2={toX}
 352 |                     y2={toY}
 353 |                   >
 354 |                   <stop offset="0%" stopColor={`rgba(${baseColor}, 0)`} />
 355 |                   <stop offset="25%" stopColor={`rgba(${baseColor}, 0.2)`} />
 356 |                   <stop offset="50%" stopColor={`rgba(${baseColor}, 0.6)`} />
 357 |                   <stop offset="75%" stopColor={`rgba(${baseColor}, 0.2)`} />
 358 |                   <stop offset="100%" stopColor={`rgba(${baseColor}, 0)`} />
 359 |                 </linearGradient>
 360 |               );
 361 |             })}
 362 |           </defs>
 363 |           
 364 |           {connections.map((connection, index) => {
 365 |             const fromStar = stars.find(s => s.id === connection.fromStarId);
 366 |             const toStar = stars.find(s => s.id === connection.toStarId);
 367 |             
 368 |             if (!fromStar || !toStar) return null;
 369 |             
 370 |               // 计算星星中心的像素坐标
 371 |             const fromX = (fromStar.x / 100) * dimensions.width;
 372 |             const fromY = (fromStar.y / 100) * dimensions.height;
 373 |             const toX = (toStar.x / 100) * dimensions.width;
 374 |             const toY = (toStar.y / 100) * dimensions.height;
 375 |             
 376 |             const isActive = fromStar.id === activeStarId || toStar.id === activeStarId;
 377 |             const connectionStrength = connection.strength || 0.3;
 378 |             
 379 |             return (
 380 |               <g key={connection.id}>
 381 |                 {/* 背景光晕层 - 最粗，营造氛围 */}
 382 |                 <motion.line
 383 |                   x1={fromX}
 384 |                   y1={fromY}
 385 |                   x2={toX}
 386 |                   y2={toY}
 387 |                   stroke={`url(#gradient-${connection.id})`}
 388 |                   strokeWidth={isActive ? 6 : Math.max(3, connectionStrength * 5)}
 389 |                   filter="blur(3px)"
 390 |                   initial={{ 
 391 |                     pathLength: 0,
 392 |                     opacity: 0 
 393 |                   }}
 394 |                   animate={{ 
 395 |                     pathLength: 1,
 396 |                     opacity: isActive 
 397 |                       ? [0.2, 0.5, 0.2] 
 398 |                       : [0.05, Math.max(0.15, connectionStrength * 0.3), 0.05]
 399 |                   }}
 400 |                   transition={{ 
 401 |                     pathLength: { duration: 2, ease: "easeInOut", delay: index * 0.1 },
 402 |                     opacity: { 
 403 |                       duration: 4 + Math.random() * 2, 
 404 |                       repeat: Infinity, 
 405 |                       ease: "easeInOut",
 406 |                       delay: index * 0.3
 407 |                     }
 408 |                   }}
 409 |                 />
 410 |                 
 411 |                 {/* 中间层 - 中等粗细，主要呼吸效果 */}
 412 |                 <motion.line
 413 |                   x1={fromX}
 414 |                   y1={fromY}
 415 |                   x2={toX}
 416 |                   y2={toY}
 417 |                   stroke={`url(#gradient-${connection.id})`}
 418 |                   strokeWidth={isActive ? 3 : Math.max(1.5, connectionStrength * 2.5)}
 419 |                   filter="blur(1px)"
 420 |                   initial={{ 
 421 |                     pathLength: 0,
 422 |                     opacity: 0 
 423 |                   }}
 424 |                   animate={{ 
 425 |                     pathLength: 1,
 426 |                     opacity: isActive 
 427 |                       ? [0.3, 0.7, 0.3] 
 428 |                       : [0.1, Math.max(0.25, connectionStrength * 0.5), 0.1]
 429 |                   }}
 430 |                   transition={{ 
 431 |                     pathLength: { duration: 2.5, ease: "easeInOut", delay: index * 0.15 },
 432 |                     opacity: { 
 433 |                       duration: 5 + Math.random() * 3, 
 434 |                       repeat: Infinity, 
 435 |                       ease: "easeInOut",
 436 |                       delay: index * 0.4 + 0.5
 437 |                     }
 438 |                   }}
 439 |                 />
 440 |                 
 441 |                 {/* 核心层 - 最细最亮，精确连接 */}
 442 |                 <motion.line
 443 |                   x1={fromX}
 444 |                   y1={fromY}
 445 |                   x2={toX}
 446 |                   y2={toY}
 447 |                   stroke={`url(#gradient-${connection.id})`}
 448 |                   strokeWidth={isActive ? 1 : Math.max(0.5, connectionStrength)}
 449 |                   initial={{ 
 450 |                     pathLength: 0,
 451 |                     opacity: 0 
 452 |                   }}
 453 |                   animate={{ 
 454 |                     pathLength: 1,
 455 |                     opacity: isActive 
 456 |                       ? [0.5, 1, 0.5] 
 457 |                       : [0.2, Math.max(0.4, connectionStrength * 0.8), 0.2]
 458 |                   }}
 459 |                   transition={{ 
 460 |                     pathLength: { duration: 3, ease: "easeInOut", delay: index * 0.2 },
 461 |                     opacity: { 
 462 |                       duration: 6 + Math.random() * 4, 
 463 |                       repeat: Infinity, 
 464 |                       ease: "easeInOut",
 465 |                       delay: index * 0.5 + 1
 466 |                     }
 467 |                   }}
 468 |                 />
 469 |                 
 470 |                 {/* 激活时的流动光点 */}
 471 |                 {isActive && (
 472 |                   <motion.circle
 473 |                     cx={fromX}
 474 |                     cy={fromY}
 475 |                     r="1.5"
 476 |                     fill="rgba(255, 255, 255, 0.9)"
 477 |                     initial={{ opacity: 0 }}
 478 |                     animate={{ 
 479 |                       cx: [fromX, toX, fromX],
 480 |                       cy: [fromY, toY, fromY],
 481 |                       opacity: [0, 1, 0]
 482 |                     }}
 483 |                     transition={{
 484 |                       duration: 3,
 485 |                       repeat: Infinity,
 486 |                       ease: "easeInOut"
 487 |                     }}
 488 |                   />
 489 |                 )}
 490 |               </g>
 491 |             );
 492 |           })}
 493 |         </svg>
 494 |         </div>
 495 |       )}
 496 |       
 497 |       {/* Stars */}
 498 |       {stars.map(star => {
 499 |         const pixelX = (star.x / 100) * dimensions.width;
 500 |         const pixelY = (star.y / 100) * dimensions.height;
 501 |         const isActive = star.id === activeStarId;
 502 |         
 503 |         // Find connected stars
 504 |         const connectedStars = connections
 505 |           .filter(conn => conn.fromStarId === star.id || conn.toStarId === star.id)
 506 |           .map(conn => conn.fromStarId === star.id ? conn.toStarId : conn.fromStarId);
 507 |         
 508 |         const hasStrongConnections = connections.some(
 509 |           conn => (conn.fromStarId === star.id || conn.toStarId === star.id) && conn.strength > 0.4
 510 |         );
 511 |         
 512 |         return (
 513 |           <Star
 514 |             key={star.id}
 515 |             x={pixelX}
 516 |             y={pixelY}
 517 |             size={star.size * (hasStrongConnections ? 1.2 : 1)}
 518 |             brightness={star.brightness}
 519 |             isSpecial={star.isSpecial || hasStrongConnections}
 520 |             isActive={isActive}
 521 |             onClick={() => handleStarClick(star.id)}
 522 |             tags={star.tags}
 523 |             category={star.primary_category} // Updated to use primary_category
 524 |             connectionCount={connectedStars.length}
 525 |           />
 526 |         );
 527 |       })}
 528 |     </div>
 529 |   );
 530 | };
 531 | 
 532 | export default Constellation;

```

`staroracle-app_allreact/src/components/ConstellationSelector.tsx`:

```tsx
   1 | import React, { useState, useEffect } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { Star, X, Flame, Mountain, Wind, Waves } from 'lucide-react';
   5 | import { getAllTemplates, getTemplatesByElement } from '../utils/constellationTemplates';
   6 | import { ConstellationTemplate } from '../types';
   7 | import { playSound } from '../utils/soundUtils';
   8 | import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
   9 | import StarRayIcon from './StarRayIcon';
  10 | 
  11 | interface ConstellationSelectorProps {
  12 |   isOpen: boolean;
  13 |   onClose: () => void;
  14 |   onSelectTemplate: (template: ConstellationTemplate) => void;
  15 | }
  16 | 
  17 | const ConstellationSelector: React.FC<ConstellationSelectorProps> = ({
  18 |   isOpen,
  19 |   onClose,
  20 |   onSelectTemplate
  21 | }) => {
  22 |   const [selectedElement, setSelectedElement] = useState<'all' | 'fire' | 'earth' | 'air' | 'water'>('all');
  23 |   const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  24 |   
  25 |   const allTemplates = getAllTemplates();
  26 |   const filteredTemplates = selectedElement === 'all' 
  27 |     ? allTemplates 
  28 |     : getTemplatesByElement(selectedElement);
  29 | 
  30 |   // 初始化iOS层级修复
  31 |   useEffect(() => {
  32 |     fixIOSZIndex();
  33 |   }, []);
  34 | 
  35 |   // 当模态框打开时隐藏其他元素
  36 |   useEffect(() => {
  37 |     if (isOpen) {
  38 |       document.body.classList.add('modal-open');
  39 |       const restore = hideOtherElements();
  40 |       setRestoreElements(() => restore);
  41 |     } else {
  42 |       document.body.classList.remove('modal-open');
  43 |       if (restoreElements) {
  44 |         restoreElements();
  45 |         setRestoreElements(null);
  46 |       }
  47 |     }
  48 |     
  49 |     return () => {
  50 |       document.body.classList.remove('modal-open');
  51 |       if (restoreElements) {
  52 |         restoreElements();
  53 |       }
  54 |     };
  55 |   }, [isOpen]);
  56 | 
  57 |   const handleClose = () => {
  58 |     playSound('starClick');
  59 |     onClose();
  60 |   };
  61 | 
  62 |   const handleSelectTemplate = (template: ConstellationTemplate) => {
  63 |     playSound('starReveal');
  64 |     onSelectTemplate(template);
  65 |     onClose();
  66 |   };
  67 | 
  68 |   const getElementIcon = (element: string) => {
  69 |     switch (element) {
  70 |       case 'fire': return <Flame className="w-4 h-4" />;
  71 |       case 'earth': return <Mountain className="w-4 h-4" />;
  72 |       case 'air': return <Wind className="w-4 h-4" />;
  73 |       case 'water': return <Waves className="w-4 h-4" />;
  74 |       default: return <Star className="w-4 h-4" />;
  75 |     }
  76 |   };
  77 | 
  78 |   const getElementColor = (element: string) => {
  79 |     switch (element) {
  80 |       case 'fire': return 'text-red-400 border-red-400';
  81 |       case 'earth': return 'text-green-400 border-green-400';
  82 |       case 'air': return 'text-blue-400 border-blue-400';
  83 |       case 'water': return 'text-cyan-400 border-cyan-400';
  84 |       default: return 'text-white border-white';
  85 |     }
  86 |   };
  87 | 
  88 |   return createPortal(
  89 |     <AnimatePresence>
  90 |       {isOpen && (
  91 |         <motion.div
  92 |           className={getMobileModalClasses()}
  93 |           style={getMobileModalStyles()}
  94 |           initial={{ opacity: 0 }}
  95 |           animate={{ opacity: 1 }}
  96 |           exit={{ opacity: 0 }}
  97 |         >
  98 |           <motion.div
  99 |             className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
 100 |             initial={{ opacity: 0 }}
 101 |             animate={{ opacity: 1 }}
 102 |             exit={{ opacity: 0 }}
 103 |             onClick={handleClose}
 104 |           />
 105 | 
 106 |           <motion.div
 107 |             className="cosmic-input rounded-lg w-full max-w-4xl mx-4 z-10 max-h-[90vh] overflow-hidden"
 108 |             initial={{ opacity: 0, y: 20, scale: 0.9 }}
 109 |             animate={{ opacity: 1, y: 0, scale: 1 }}
 110 |             exit={{ opacity: 0, y: 20, scale: 0.9 }}
 111 |             transition={{ type: 'spring', damping: 25 }}
 112 |           >
 113 |             <div className="p-6">
 114 |               {/* Header */}
 115 |               <div className="flex items-center justify-between mb-6">
 116 |                 <div className="flex items-center gap-3">
 117 |                   <StarRayIcon size={24} className="text-cosmic-accent" animated={true} />
 118 |                   <h2 className="stellar-title text-white">选择星座模板</h2>
 119 |                 </div>
 120 |                 <button
 121 |                   className="w-8 h-8 rounded-full cosmic-button flex items-center justify-center"
 122 |                   onClick={handleClose}
 123 |                 >
 124 |                   <X className="w-4 h-4 text-white" />
 125 |                 </button>
 126 |               </div>
 127 | 
 128 |               {/* Element Filter */}
 129 |               <div className="flex gap-2 mb-6 overflow-x-auto">
 130 |                 {[
 131 |                   { key: 'all', label: '全部', icon: <Star className="w-4 h-4" /> },
 132 |                   { key: 'fire', label: '火象', icon: <Flame className="w-4 h-4" /> },
 133 |                   { key: 'earth', label: '土象', icon: <Mountain className="w-4 h-4" /> },
 134 |                   { key: 'air', label: '风象', icon: <Wind className="w-4 h-4" /> },
 135 |                   { key: 'water', label: '水象', icon: <Waves className="w-4 h-4" /> }
 136 |                 ].map(({ key, label, icon }) => (
 137 |                   <button
 138 |                     key={key}
 139 |                     className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-all ${
 140 |                       selectedElement === key
 141 |                         ? 'bg-cosmic-accent bg-opacity-20 border-cosmic-accent text-cosmic-accent'
 142 |                         : 'cosmic-button text-white'
 143 |                     }`}
 144 |                     onClick={() => setSelectedElement(key as any)}
 145 |                   >
 146 |                     {icon}
 147 |                     <span className="text-sm font-medium">{label}</span>
 148 |                   </button>
 149 |                 ))}
 150 |               </div>
 151 | 
 152 |               {/* Templates Grid */}
 153 |               <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
 154 |                 <AnimatePresence>
 155 |                   {filteredTemplates.map((template, index) => (
 156 |                     <motion.div
 157 |                       key={template.id}
 158 |                       className="constellation-template-card"
 159 |                       initial={{ opacity: 0, y: 20 }}
 160 |                       animate={{ opacity: 1, y: 0 }}
 161 |                       exit={{ opacity: 0, y: -20 }}
 162 |                       transition={{ delay: index * 0.1 }}
 163 |                       whileHover={{ y: -5 }}
 164 |                       onClick={() => handleSelectTemplate(template)}
 165 |                     >
 166 |                       {/* Template Preview */}
 167 |                       <div className="template-preview">
 168 |                         <svg className="w-full h-24" viewBox="0 0 100 60">
 169 |                           {/* Draw template stars */}
 170 |                           {template.stars.map((star, i) => (
 171 |                             <g key={i}>
 172 |                               <circle
 173 |                                 cx={50 + star.x * 2}
 174 |                                 cy={30 + star.y * 2}
 175 |                                 r={star.size * 0.8}
 176 |                                 fill={star.isMainStar ? '#8A5FBD' : '#ffffff'}
 177 |                                 opacity={star.brightness}
 178 |                               />
 179 |                               {star.isMainStar && (
 180 |                                 <circle
 181 |                                   cx={50 + star.x * 2}
 182 |                                   cy={30 + star.y * 2}
 183 |                                   r={star.size * 1.2}
 184 |                                   fill="none"
 185 |                                   stroke="#8A5FBD"
 186 |                                   strokeWidth="0.5"
 187 |                                   opacity="0.6"
 188 |                                 />
 189 |                               )}
 190 |                             </g>
 191 |                           ))}
 192 |                           
 193 |                           {/* Draw template connections */}
 194 |                           {template.connections.map((conn, i) => {
 195 |                             const fromStar = template.stars.find(s => s.id === conn.fromStarId);
 196 |                             const toStar = template.stars.find(s => s.id === conn.toStarId);
 197 |                             if (!fromStar || !toStar) return null;
 198 |                             
 199 |                             return (
 200 |                               <line
 201 |                                 key={i}
 202 |                                 x1={50 + fromStar.x * 2}
 203 |                                 y1={30 + fromStar.y * 2}
 204 |                                 x2={50 + toStar.x * 2}
 205 |                                 y2={30 + toStar.y * 2}
 206 |                                 stroke="rgba(255,255,255,0.3)"
 207 |                                 strokeWidth="0.5"
 208 |                               />
 209 |                             );
 210 |                           })}
 211 |                         </svg>
 212 |                       </div>
 213 | 
 214 |                       {/* Template Info */}
 215 |                       <div className="template-info">
 216 |                         <div className="flex items-center justify-between mb-2">
 217 |                           <h3 className="font-heading text-white text-lg">{template.chineseName}</h3>
 218 |                           <div className={`flex items-center gap-1 px-2 py-1 rounded-full border text-xs ${getElementColor(template.element)}`}>
 219 |                             {getElementIcon(template.element)}
 220 |                             <span>{template.element}</span>
 221 |                           </div>
 222 |                         </div>
 223 |                         
 224 |                         <p className="text-sm text-gray-300 mb-3">{template.description}</p>
 225 |                         
 226 |                         <div className="flex items-center justify-between text-xs text-gray-400">
 227 |                           <span>{template.stars.length} 颗星</span>
 228 |                           <span>{template.connections.length} 条连线</span>
 229 |                         </div>
 230 |                       </div>
 231 |                     </motion.div>
 232 |                   ))}
 233 |                 </AnimatePresence>
 234 |               </div>
 235 | 
 236 |               {/* Info */}
 237 |               <div className="mt-6 p-4 bg-cosmic-purple bg-opacity-10 border border-cosmic-purple border-opacity-20 rounded-md">
 238 |                 <p className="text-sm text-gray-300">
 239 |                   <strong>提示:</strong> 选择一个星座模板作为你的星空基础。你可以在此基础上继续添加自己的星星，
 240 |                   创造独特的个人星座。模板星星会以特殊样式显示，与你后续添加的星星形成美丽的连接。
 241 |                 </p>
 242 |               </div>
 243 |             </div>
 244 |           </motion.div>
 245 |         </motion.div>
 246 |       )}
 247 |     </AnimatePresence>,
 248 |     createTopLevelContainer()
 249 |   );
 250 | };
 251 | 
 252 | export default ConstellationSelector;

```

`staroracle-app_allreact/src/components/ConversationDrawer.tsx`:

```tsx
   1 | import React, { useState, useRef, useEffect, useCallback } from 'react';
   2 | import { Mic } from 'lucide-react';
   3 | import { playSound } from '../utils/soundUtils';
   4 | import { triggerHapticFeedback } from '../utils/hapticUtils';
   5 | import StarRayIcon from './StarRayIcon';
   6 | import FloatingAwarenessPlanet from './FloatingAwarenessPlanet';
   7 | import { Capacitor } from '@capacitor/core';
   8 | import { useChatStore } from '../store/useChatStore';
   9 | 
  10 | // iOS设备检测
  11 | const isIOS = () => {
  12 |   return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
  13 |          (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  14 | };
  15 | 
  16 | interface ConversationDrawerProps {
  17 |   isOpen: boolean;
  18 |   onToggle: () => void;
  19 |   onSendMessage?: (inputText: string) => void; // ✨ 新增：发送消息的回调
  20 |   showChatHistory?: boolean; // 新增是否显示聊天历史的开关
  21 |   followUpQuestion?: string; // 外部传入的后续问题
  22 |   onFollowUpProcessed?: () => void; // 后续问题处理完成的回调
  23 |   isFloatingAttached?: boolean; // 新增：是否有浮窗吸附状态
  24 | }
  25 | 
  26 | const ConversationDrawer: React.FC<ConversationDrawerProps> = ({ 
  27 |   isOpen, 
  28 |   onToggle, 
  29 |   onSendMessage, // ✨ 使用新 prop
  30 |   showChatHistory = true,
  31 |   followUpQuestion, 
  32 |   onFollowUpProcessed,
  33 |   isFloatingAttached = false // 新增参数
  34 | }) => {
  35 |   const [inputValue, setInputValue] = useState('');
  36 |   const [isRecording, setIsRecording] = useState(false);
  37 |   const [starAnimated, setStarAnimated] = useState(false);
  38 |   const inputRef = useRef<HTMLInputElement>(null);
  39 |   const containerRef = useRef<HTMLDivElement>(null);
  40 |   
  41 |   const { conversationAwareness } = useChatStore();
  42 | 
  43 |   // 移除所有键盘监听逻辑，让系统原生处理键盘行为
  44 | 
  45 |   const handleMicClick = () => {
  46 |     setIsRecording(!isRecording);
  47 |     console.log('Microphone clicked, recording:', !isRecording);
  48 |     if (Capacitor.isNativePlatform()) {
  49 |       triggerHapticFeedback('light');
  50 |     }
  51 |     playSound('starClick');
  52 |   };
  53 | 
  54 |   const handleStarClick = () => {
  55 |     setStarAnimated(true);
  56 |     console.log('Star ray button clicked');
  57 |     if (inputValue.trim()) {
  58 |       handleSend();
  59 |     }
  60 |     setTimeout(() => {
  61 |       setStarAnimated(false);
  62 |     }, 1000);
  63 |   };
  64 | 
  65 |   const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  66 |     setInputValue(e.target.value);
  67 |   };
  68 | 
  69 |   // 发送处理 - 调用新的 onSendMessage
  70 |   const handleSend = useCallback(async () => {
  71 |     const trimmedInput = inputValue.trim();
  72 |     if (!trimmedInput) return;
  73 |     
  74 |     // ✨ 调用新的 onSendMessage 回调
  75 |     if (onSendMessage) {
  76 |       onSendMessage(trimmedInput);
  77 |     }
  78 |     
  79 |     // 发送后立即清空输入框
  80 |     setInputValue('');
  81 |     
  82 |     console.log('🔍 ConversationDrawer: 消息已发送，请求打开ChatOverlay');
  83 |   }, [inputValue, onSendMessage]); // ✨ 更新依赖
  84 | 
  85 |   const handleKeyPress = (e: React.KeyboardEvent) => {
  86 |     if (e.key === 'Enter') {
  87 |       handleSend();
  88 |     }
  89 |   };
  90 | 
  91 |   // 移除所有输入框点击控制，让系统原生处理
  92 | 
  93 |   // 完全移除样式计算，让系统原生处理所有定位
  94 |   const getContainerStyle = () => {
  95 |     // 只保留最基本的底部空间，移除所有动态计算
  96 |     return isFloatingAttached 
  97 |       ? { paddingBottom: '70px' } 
  98 |       : { paddingBottom: '1rem' }; // 使用固定值而不是env()
  99 |   };
 100 | 
 101 |   return (
 102 |     <div 
 103 |       ref={containerRef}
 104 |       className="fixed bottom-0 left-0 right-0 z-50 p-4 pointer-events-none" // 移除keyboard-aware-container，让系统原生处理
 105 |       style={getContainerStyle()}
 106 |     >
 107 |       <div className="w-full max-w-md mx-auto pointer-events-auto"> {/* 只有内容区域可点击 */}
 108 |         <div className="relative">
 109 |           <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
 110 |             {/* 左侧：觉察动画 */}
 111 |             <div className="ml-3 flex-shrink-0">
 112 |               <FloatingAwarenessPlanet
 113 |                 level={conversationAwareness.overallLevel}
 114 |                 isAnalyzing={conversationAwareness.isAnalyzing}
 115 |                 conversationDepth={conversationAwareness.conversationDepth}
 116 |                 onTogglePanel={() => {
 117 |                   console.log('觉察动画被点击');
 118 |                   // TODO: 实现觉察详情面板
 119 |                 }}
 120 |               />
 121 |             </div>
 122 |             
 123 |             {/* Input field - 调整padding避免与左侧动画重叠 */}
 124 |             <input
 125 |               ref={inputRef}
 126 |               type="text"
 127 |               value={inputValue}
 128 |               onChange={handleInputChange}
 129 |               onKeyPress={handleKeyPress}
 130 |               // 🚨 关键：移除所有 onClick 和 onFocus 事件处理器，让其行为原生化
 131 |               placeholder="询问任何问题"
 132 |               className="flex-1 bg-transparent text-white placeholder-gray-400 pl-2 pr-4 py-2 focus:outline-none stellar-body"
 133 |               // iOS专用属性确保键盘弹起
 134 |               inputMode="text"
 135 |               autoComplete="off"
 136 |               autoCapitalize="sentences"
 137 |               spellCheck="false"
 138 |             />
 139 | 
 140 |             <div className="flex items-center space-x-2 mr-3">
 141 |               {/* 修正点 1: 麦克风按钮 - 使用新的CSS类解决iOS问题 */}
 142 |               <button
 143 |                 type="button"
 144 |                 onClick={handleMicClick}
 145 |                 className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
 146 |                   isRecording 
 147 |                     ? 'recording' 
 148 |                     : ''
 149 |                 }`}
 150 |               >
 151 |                 <Mic className="w-4 h-4" strokeWidth={2} />
 152 |               </button>
 153 | 
 154 |               {/* 修正点 2: 星星按钮 - 使用新的CSS类解决iOS问题 */}
 155 |               <button
 156 |                 type="button"
 157 |                 onClick={handleStarClick}
 158 |                 className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
 159 |               >
 160 |                 <StarRayIcon 
 161 |                   size={16} 
 162 |                   animated={starAnimated || !!inputValue.trim()} 
 163 |                   iconColor="currentColor"
 164 |                 />
 165 |               </button>
 166 |             </div>
 167 |           </div>
 168 | 
 169 |           {/* Recording indicator */}
 170 |           {isRecording && (
 171 |             <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
 172 |               <div className="flex items-center space-x-2 text-red-400 text-xs">
 173 |                 <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
 174 |                 <span>Recording...</span>
 175 |               </div>
 176 |             </div>
 177 |           )}
 178 |         </div>
 179 |       </div>
 180 |     </div>
 181 |   );
 182 | };
 183 | 
 184 | export default ConversationDrawer;

```

`staroracle-app_allreact/src/components/DrawerMenu.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { 
   4 |   X, 
   5 |   ChevronRight 
   6 | } from 'lucide-react';
   7 | 
   8 | interface DrawerMenuProps {
   9 |   isOpen: boolean;
  10 |   onClose: () => void;
  11 |   onOpenSettings: () => void;
  12 |   onOpenTemplateSelector: () => void;
  13 | }
  14 | 
  15 | const DrawerMenu: React.FC<DrawerMenuProps> = ({ isOpen, onClose, onOpenSettings, onOpenTemplateSelector }) => {
  16 |   // 菜单项配置（基于demo的设计）
  17 |   const menuItems = [
  18 |     { label: '所有项目', active: true },
  19 |     { label: '记忆', count: 0 },
  20 |     { 
  21 |       label: '选择星座', 
  22 |       hasArrow: true,
  23 |       onClick: () => {
  24 |         onOpenTemplateSelector();
  25 |         onClose();
  26 |       }
  27 |     },
  28 |     { label: '智能标签', count: 9, section: '资料库' },
  29 |     { label: '人物', count: 0 },
  30 |     { label: '事物', count: 0 },
  31 |     { label: '地点', count: 0 },
  32 |     { label: '类型' },
  33 |     { 
  34 |       label: 'AI配置', 
  35 |       hasArrow: true,
  36 |       onClick: () => {
  37 |         onOpenSettings();
  38 |         onClose();
  39 |       }
  40 |     },
  41 |     { label: '导入', hasArrow: true }
  42 |   ];
  43 | 
  44 |   return (
  45 |     <AnimatePresence>
  46 |       {isOpen && (
  47 |         <div className="fixed inset-0 z-50 flex">
  48 |           {/* 抽屉内容 */}
  49 |           <motion.div
  50 |             initial={{ x: -320 }}
  51 |             animate={{ x: 0 }}
  52 |             exit={{ x: -320 }}
  53 |             transition={{ type: "spring", damping: 25, stiffness: 200 }}
  54 |             className="w-80 h-full shadow-2xl"
  55 |             style={{
  56 |               background: 'linear-gradient(135deg, rgba(27, 39, 53, 0.95) 0%, rgba(9, 10, 15, 0.98) 100%)',
  57 |               backdropFilter: 'blur(20px)'
  58 |             }}
  59 |           >
  60 |             {/* 抽屉顶部 - 与主页Header位置对齐 */}
  61 |             <div 
  62 |               className="px-5 border-b border-white/10"
  63 |               style={{
  64 |                 paddingLeft: `calc(1.25rem + var(--safe-area-inset-left, 0px))`, // 20px + 安全区域
  65 |                 paddingRight: `calc(1.25rem + var(--safe-area-inset-right, 0px))`, // 20px + 安全区域
  66 |                 paddingTop: '3rem', // 48px - 与Header完全一致
  67 |                 paddingBottom: '0.5rem' // 8px - 与Header完全一致
  68 |               }}
  69 |             >
  70 |               <div className="flex items-center justify-between">
  71 |                 <div className="stellar-title text-white">StarOracle</div>
  72 |                 <button
  73 |                   onClick={onClose}
  74 |                   className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
  75 |                 >
  76 |                   <X className="w-5 h-5" />
  77 |                 </button>
  78 |               </div>
  79 |             </div>
  80 | 
  81 |             {/* 菜单项列表 */}
  82 |             <div className="flex-1 overflow-y-auto">
  83 |               {menuItems.map((item, index) => {
  84 |                 return (
  85 |                   <div key={index}>
  86 |                     {/* 分组标题 */}
  87 |                     {item.section && (
  88 |                       <div className="px-5 py-3 text-xs text-white/40 font-medium tracking-wide uppercase">
  89 |                         {item.section}
  90 |                       </div>
  91 |                     )}
  92 |                     
  93 |                     {/* 菜单项 */}
  94 |                     <div 
  95 |                       className={`flex items-center justify-between px-5 py-4 cursor-pointer transition-all duration-200 ${
  96 |                         item.active 
  97 |                           ? 'text-white border-r-2 border-blue-400' 
  98 |                           : 'text-white/60 hover:text-white'
  99 |                       }`}
 100 |                       onClick={item.onClick}
 101 |                     >
 102 |                       <div className="flex items-center">
 103 |                         <span className="stellar-body">{item.label}</span>
 104 |                       </div>
 105 |                       
 106 |                       <div className="flex items-center gap-2">
 107 |                         {typeof item.count === 'number' && (
 108 |                           <span className={`text-sm ${
 109 |                             item.active 
 110 |                               ? 'text-blue-300' 
 111 |                               : 'text-white/40'
 112 |                           }`}>
 113 |                             {item.count}
 114 |                           </span>
 115 |                         )}
 116 |                         {item.hasArrow && (
 117 |                           <ChevronRight className="w-4 h-4 text-white/40" />
 118 |                         )}
 119 |                       </div>
 120 |                     </div>
 121 |                   </div>
 122 |                 );
 123 |               })}
 124 |             </div>
 125 | 
 126 |             {/* 底部用户信息 */}
 127 |             <div className="px-5 py-4 border-t border-white/10 backdrop-blur-sm" 
 128 |                  style={{ background: 'rgba(255, 255, 255, 0.02)' }}>
 129 |               <div className="flex items-center gap-3">
 130 |                 <div className="w-8 h-8 bg-gradient-to-r from-blue-400 to-cyan-400 rounded-full flex items-center justify-center text-white text-sm font-bold">
 131 |                   ✦
 132 |                 </div>
 133 |                 <div className="flex-1">
 134 |                   <div className="stellar-body text-white">星谕用户</div>
 135 |                   <div className="text-xs text-white/60">探索星辰的奥秘</div>
 136 |                 </div>
 137 |               </div>
 138 |             </div>
 139 |           </motion.div>
 140 | 
 141 |           {/* 背景遮罩 */}
 142 |           <motion.div 
 143 |             initial={{ opacity: 0 }}
 144 |             animate={{ opacity: 1 }}
 145 |             exit={{ opacity: 0 }}
 146 |             className="flex-1 bg-black/50 backdrop-blur-sm"
 147 |             onClick={onClose}
 148 |           />
 149 |         </div>
 150 |       )}
 151 |     </AnimatePresence>
 152 |   );
 153 | };
 154 | 
 155 | export default DrawerMenu;

```

`staroracle-app_allreact/src/components/FloatingAwarenessPlanet.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | 
   4 | interface FloatingAwarenessPlanetProps {
   5 |   level: 'none' | 'low' | 'medium' | 'high';
   6 |   isAnalyzing: boolean;
   7 |   conversationDepth: number; // 0-100 的对话深度百分比
   8 |   onTogglePanel?: () => void;
   9 | }
  10 | 
  11 | const FloatingAwarenessPlanet: React.FC<FloatingAwarenessPlanetProps> = ({
  12 |   level,
  13 |   isAnalyzing,
  14 |   conversationDepth,
  15 |   onTogglePanel
  16 | }) => {
  17 |   // 根据觉察等级配置星星颜色，从灰色到明亮紫色
  18 |   const getStarColor = () => {
  19 |     if (isAnalyzing) {
  20 |       return '#8A5FBD'; // 明亮紫色
  21 |     }
  22 |     
  23 |     // 计算从灰色到紫色的渐变
  24 |     const progress = 
  25 |       level === 'none' ? 0 :
  26 |       level === 'low' ? 0.33 :
  27 |       level === 'medium' ? 0.66 :
  28 |       level === 'high' ? 1 : 0;
  29 |     
  30 |     // 从灰色 #888888 到明亮紫色 #8A5FBD
  31 |     const gray = { r: 136, g: 136, b: 136 };
  32 |     const purple = { r: 138, g: 95, b: 189 };
  33 |     
  34 |     const r = Math.round(gray.r + (purple.r - gray.r) * progress);
  35 |     const g = Math.round(gray.g + (purple.g - gray.g) * progress);
  36 |     const b = Math.round(gray.b + (purple.b - gray.b) * progress);
  37 |     
  38 |     return `rgb(${r}, ${g}, ${b})`;
  39 |   };
  40 | 
  41 |   const starColor = getStarColor();
  42 |   const isActive = level !== 'none' || isAnalyzing;
  43 | 
  44 |   return (
  45 |     <motion.div
  46 |       className="cursor-pointer" // 移除fixed定位，适应输入框内部
  47 |       style={{ 
  48 |         width: '32px', // 缩小尺寸适应输入框
  49 |         height: '32px',
  50 |         display: 'flex',
  51 |         alignItems: 'center',
  52 |         justifyContent: 'center'
  53 |       }}
  54 |       initial={{ scale: 0, opacity: 0 }}
  55 |       animate={{ 
  56 |         scale: 1, 
  57 |         opacity: 1
  58 |       }}
  59 |       whileHover={{ scale: 1.1 }}
  60 |       whileTap={{ scale: 0.9 }}
  61 |       onClick={onTogglePanel}
  62 |       transition={{ duration: 0.3, ease: "easeOut" }}
  63 |     >
  64 |       {/* BURST 动画：使用原版参数，调整尺寸适应输入框 */}
  65 |       <svg width="32" height="32" viewBox="0 0 32 32">
  66 |         {/* 中心点 */}
  67 |         <motion.circle
  68 |           cx="16" // 调整中心点到32px容器的中心
  69 |           cy="16"
  70 |           r="1.5" // 缩小中心点
  71 |           fill={starColor}
  72 |           animate={isActive ? {
  73 |             scale: [1, 1.2, 1],
  74 |             opacity: [0.8, 1, 0.8]
  75 |           } : {}}
  76 |           transition={{
  77 |             duration: 2,
  78 |             repeat: isActive ? Infinity : 0,
  79 |             ease: "easeInOut"
  80 |           }}
  81 |         />
  82 |         
  83 |         {/* 12条随机长度射线 - 缩放适应32px容器 */}
  84 |         {Array.from({ length: 12 }).map((_, i) => {
  85 |           const angle = (i * Math.PI * 2) / 12;
  86 |           const seedRandom = (seed: number) => {
  87 |             const x = Math.sin(seed) * 10000;
  88 |             return x - Math.floor(x);
  89 |           };
  90 |           const length = 5 + seedRandom(i) * 8; // 缩小长度适应32px容器
  91 |           const strokeWidth = seedRandom(i + 12) * 1.2 + 0.3; // 缩小线宽
  92 |           
  93 |           return (
  94 |             <motion.line
  95 |               key={`burst-${i}`}
  96 |               x1="16" // 调整到32px容器的中心
  97 |               y1="16"
  98 |               x2={16 + Math.cos(angle) * length}
  99 |               y2={16 + Math.sin(angle) * length}
 100 |               stroke={starColor}
 101 |               strokeWidth={strokeWidth}
 102 |               strokeLinecap="round"
 103 |               initial={{ pathLength: 0, opacity: 0 }}
 104 |               animate={isActive ? { 
 105 |                 pathLength: [0, 1, 0],
 106 |                 opacity: [0, 0.7, 0],
 107 |               } : { pathLength: 0, opacity: 0.2 }}
 108 |               transition={{
 109 |                 duration: 2 + seedRandom(i + 24),
 110 |                 delay: i * 0.05,
 111 |                 repeat: isActive ? Infinity : 0,
 112 |                 repeatDelay: seedRandom(i + 36),
 113 |               }}
 114 |             />
 115 |           );
 116 |         })}
 117 |       </svg>
 118 |     </motion.div>
 119 |   );
 120 | };
 121 | 
 122 | export default FloatingAwarenessPlanet;

```

`staroracle-app_allreact/src/components/Header.tsx`:

```tsx
   1 | import React from 'react';
   2 | import StarRayIcon from './StarRayIcon';
   3 | import { Menu } from 'lucide-react';
   4 | 
   5 | interface HeaderProps {
   6 |   onOpenDrawerMenu: () => void;
   7 |   onLogoClick: () => void;
   8 | }
   9 | 
  10 | const Header: React.FC<HeaderProps> = ({ onOpenDrawerMenu, onLogoClick }) => {
  11 |   return (
  12 |     <>      
  13 |       <header 
  14 |         className="fixed top-0 left-0 right-0 z-50"
  15 |         style={{
  16 |           paddingLeft: `calc(1rem + var(--safe-area-inset-left, 0px))`,
  17 |           paddingRight: `calc(1rem + var(--safe-area-inset-right, 0px))`,
  18 |           // 使用与DrawerMenu相同的简单padding策略，但增加一个标题高度的距离
  19 |           paddingTop: '3rem', // 48px，在原来24px基础上增加24px，避免被灵动岛遮挡
  20 |           paddingBottom: '0.5rem', // 8px底部间距
  21 |           // 添加背景，让其延伸到屏幕最顶端实现沉浸效果
  22 |           background: 'rgba(0, 0, 0, 0.1)',
  23 |           backdropFilter: 'blur(10px)'
  24 |         }}
  25 |       >
  26 |         <div className="flex justify-between items-center h-full">
  27 |         {/* 左侧菜单按钮 */}
  28 |         <button
  29 |           className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
  30 |           onClick={onOpenDrawerMenu}
  31 |           title="菜单"
  32 |         >
  33 |           <Menu className="w-4 h-4" />
  34 |         </button>
  35 | 
  36 |         {/* 中间标题 */}
  37 |         <h1 className="stellar-title text-white flex items-center">
  38 |           <span>星谕</span>
  39 |           <span className="ml-2 text-xs opacity-70">(StarOracle)</span>
  40 |         </h1>
  41 | 
  42 |         {/* 右侧logo按钮 */}
  43 |         <button
  44 |           className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
  45 |           onClick={onLogoClick}
  46 |           title="集星"
  47 |         >
  48 |           <StarRayIcon 
  49 |             size={18} 
  50 |             animated={false} 
  51 |             iconColor="#a855f7"
  52 |           />
  53 |         </button>
  54 |       </div>
  55 |     </header>
  56 |     </>
  57 |   );
  58 | };
  59 | 
  60 | export default Header;

```

`staroracle-app_allreact/src/components/InspirationCard.tsx`:

```tsx
   1 | import React, { useState, useEffect, useRef } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { Sparkles, MessageCircle } from 'lucide-react';
   5 | import { InspirationCard as IInspirationCard } from '../utils/inspirationCards';
   6 | import { useStarStore } from '../store/useStarStore';
   7 | import { playSound } from '../utils/soundUtils';
   8 | import { getBookAnswer, getAnswerReflection } from '../utils/bookOfAnswers';
   9 | import ConversationDrawer from './ConversationDrawer';
  10 | import StarRayIcon from './StarRayIcon';
  11 | 
  12 | interface InspirationCardProps {
  13 |   card: IInspirationCard;
  14 |   onDismiss: () => void;
  15 | }
  16 | 
  17 | const InspirationCard: React.FC<InspirationCardProps> = ({ card, onDismiss }) => {
  18 |   const { addStar } = useStarStore();
  19 |   const [isFlipped, setIsFlipped] = useState(false);
  20 |   const [bookAnswer, setBookAnswer] = useState('');
  21 |   const [answerReflection, setAnswerReflection] = useState('');
  22 |   const [inputValue, setInputValue] = useState('');
  23 |   const [isCardReady, setIsCardReady] = useState(false); // 控制内部动画何时开始
  24 |   const inputRef = useRef<HTMLInputElement>(null);
  25 |   
  26 |   // 预生成固定的星星位置，避免重新渲染时跳变
  27 |   const [starPositions] = useState(() => 
  28 |     Array.from({ length: 12 }).map((_, i) => ({
  29 |       cx: 20 + (i % 4) * 40 + Math.random() * 20,
  30 |       cy: 20 + Math.floor(i / 4) * 40 + Math.random() * 20,
  31 |       r: Math.random() * 1.5 + 0.5,
  32 |       duration: 2 + Math.random() * 2,
  33 |       delay: Math.random() * 2
  34 |     }))
  35 |   );
  36 |   
  37 |   // 预生成固定的装饰粒子位置
  38 |   const [particlePositions] = useState(() => 
  39 |     Array.from({ length: 6 }).map(() => ({
  40 |       left: `${20 + Math.random() * 60}%`,
  41 |       top: `${20 + Math.random() * 60}%`,
  42 |       duration: 3 + Math.random() * 2,
  43 |       delay: Math.random() * 2
  44 |     }))
  45 |   );
  46 |   
  47 |   // 在组件挂载时生成答案，确保答案在整个卡片生命周期内保持不变
  48 |   useEffect(() => {
  49 |     const answer = getBookAnswer();
  50 |     const reflection = getAnswerReflection(answer);
  51 |     setBookAnswer(answer);
  52 |     setAnswerReflection(reflection);
  53 |   }, []);
  54 | 
  55 |   // 延迟启动内部动画，等待卡片容器动画完成
  56 |   useEffect(() => {
  57 |     const timer = setTimeout(() => {
  58 |       setIsCardReady(true);
  59 |     }, 0); // 减少延迟时间，加快主星星出现
  60 | 
  61 |     return () => clearTimeout(timer);
  62 |   }, []);
  63 |     
  64 |   // 移除自动聚焦功能 - 只有用户手动点击输入框时才触发键盘
  65 |   // useEffect(() => {
  66 |   //   if (isFlipped && inputRef.current) {
  67 |   //     setTimeout(() => {
  68 |   //       inputRef.current?.focus();
  69 |   //     }, 600); // 等待卡片翻转动画完成
  70 |   //   }
  71 |   // }, [isFlipped]);
  72 | 
  73 |   const handleDismiss = () => {
  74 |     playSound('starClick');
  75 |     onDismiss();
  76 |   };
  77 | 
  78 |   const handleCardClick = () => {
  79 |     setIsFlipped(!isFlipped);
  80 |     playSound('starClick');
  81 |   };
  82 |   
  83 |   const handleSendMessage = () => {
  84 |     if (inputValue.trim()) {
  85 |       // 这里可以处理发送消息的逻辑
  86 |       console.log("发送消息:", inputValue);
  87 |       // 示例：创建一个新的星星
  88 |       addStar(inputValue);
  89 |       setInputValue('');
  90 |       playSound('starClick');
  91 |     }
  92 |   };
  93 | 
  94 |   const handleKeyPress = (e: React.KeyboardEvent) => {
  95 |     if (e.key === 'Enter' && !e.shiftKey) {
  96 |       e.preventDefault();
  97 |       handleSendMessage();
  98 |     }
  99 |   };
 100 | 
 101 |   // 为卡片生成唯一ID，用于渐变效果
 102 |   const cardId = `insp-${Date.now()}`;
 103 | 
 104 |   return createPortal(
 105 |     <motion.div
 106 |       className="fixed inset-0 flex items-center justify-center"
 107 |       style={{ zIndex: 999999 }}
 108 |       initial={{ opacity: 0 }}
 109 |       animate={{ opacity: 1 }}
 110 |       exit={{ opacity: 0 }}
 111 |     >
 112 |       <motion.div
 113 |         className="absolute inset-0 bg-black"
 114 |         style={{ opacity: 0.7 }}
 115 |         initial={{ opacity: 0 }}
 116 |         animate={{ opacity: 0.7 }}
 117 |         exit={{ opacity: 0 }}
 118 |         onClick={handleDismiss}
 119 |       />
 120 |       
 121 |       <motion.div
 122 |         className="star-card-container"
 123 |         initial={{ opacity: 0, scale: 0.9 }}
 124 |         animate={{ opacity: 1, scale: 1 }}
 125 |         transition={{ type: "spring", damping: 20 }}
 126 |       >
 127 |         <div className="star-card-wrapper">
 128 |           <motion.div
 129 |             className="star-card"
 130 |             animate={{ rotateY: isFlipped ? 180 : 0 }}
 131 |             transition={{ duration: 0.6, type: "spring" }}
 132 |             onClick={handleCardClick}
 133 |           >
 134 |             {/* Front Side - Card Design */}
 135 |             <div className="star-card-face star-card-front">
 136 |               <div className="star-card-bg">
 137 |                 <div className="star-card-constellation">
 138 |                   {/* Star pattern */}
 139 |                   <svg className="constellation-svg" viewBox="0 0 200 200">
 140 |               <defs>
 141 |                       <radialGradient id={`starGlow-${cardId}`} cx="50%" cy="50%" r="50%">
 142 |                         <stop offset="0%" stopColor="#ffffff" stopOpacity="0.8"/>
 143 |                         <stop offset="100%" stopColor="#ffffff" stopOpacity="0"/>
 144 |                 </radialGradient>
 145 |               </defs>
 146 |               
 147 |               {/* Background stars */}
 148 |                     {starPositions.map((star, i) => (
 149 |                 <motion.circle
 150 |                   key={i}
 151 |                         cx={star.cx}
 152 |                         cy={star.cy}
 153 |                   r={star.r}
 154 |                   fill="rgba(255,255,255,0.6)"
 155 |                   initial={{ opacity: 0 }}
 156 |                   animate={isCardReady ? {
 157 |                     opacity: [0.3, 0.8, 0.3]
 158 |                   } : {
 159 |                     opacity: 0
 160 |                   }}
 161 |                   transition={{
 162 |                     duration: star.duration,
 163 |                     repeat: isCardReady ? Infinity : 0,
 164 |                     delay: isCardReady ? 2.0 + star.delay : 0
 165 |                   }}
 166 |                 />
 167 |               ))}
 168 |               
 169 |                     {/* Main star */}
 170 |                     <motion.circle
 171 |                       cx="100"
 172 |                 cy="100"
 173 |                       r="8"
 174 |                       fill={`url(#starGlow-${cardId})`}
 175 |                       initial={{ scale: 0 }}
 176 |                       animate={isCardReady ? { scale: 1 } : { scale: 0 }}
 177 |                       transition={{ delay: isCardReady ? 0.1 : 0, type: "spring", damping: 15 }}
 178 |                     />
 179 |                     
 180 |                     {/* Star rays - 使用星星动画阶段的动画效果 */}
 181 |                     {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
 182 |                       <motion.line
 183 |                         key={i}
 184 |                         x1="100"
 185 |                         y1="100"
 186 |                         x2={100 + Math.cos(i * Math.PI / 4) * 40}
 187 |                         y2={100 + Math.sin(i * Math.PI / 4) * 40}
 188 |                         stroke="#ffffff"
 189 |                         strokeWidth="2"
 190 |                         initial={{ pathLength: 0, opacity: 0 }}
 191 |                         animate={isCardReady ? {
 192 |                           pathLength: 1,
 193 |                           opacity: [0, 0.8, 0]
 194 |                         } : {
 195 |                           pathLength: 0,
 196 |                           opacity: 0
 197 |                         }}
 198 |                         transition={{
 199 |                           duration: 1.5,
 200 |                           delay: isCardReady ? i * 0.1 : 0,
 201 |                           repeat: isCardReady ? Infinity : 0,
 202 |                           repeatDelay: isCardReady ? 1 : 0
 203 |                         }}
 204 |               />
 205 |                     ))}
 206 |             </svg>
 207 |           </div>
 208 | 
 209 |                 <motion.div
 210 |                   className="card-prompt"
 211 |                   initial={{ opacity: 0, y: 20 }}
 212 |                   animate={isCardReady ? {
 213 |                     opacity: 0.7,
 214 |                     y: 0
 215 |                   } : {
 216 |                     opacity: 0,
 217 |                     y: 20
 218 |                   }}
 219 |                   transition={{ 
 220 |                     delay: isCardReady ? 0.5 : 0,
 221 |                     duration: 0.3
 222 |                   }}
 223 |                 >
 224 |                   <p className="text-center text-base text-neutral-300 font-normal">
 225 |                     翻开卡片，宇宙会回答你
 226 |                   </p>
 227 |                 </motion.div>
 228 | 
 229 |                 {/* Decorative elements */}
 230 |                 <div className="star-card-decorations">
 231 |                   {particlePositions.map((particle, i) => (
 232 |             <motion.div
 233 |               key={i}
 234 |               className="floating-particle"
 235 |               style={{
 236 |                 left: particle.left,
 237 |                 top: particle.top,
 238 |               }}
 239 |               initial={{ y: 0, opacity: 0.3 }}
 240 |               animate={isCardReady ? {
 241 |                 y: [-5, 5, -5],
 242 |                 opacity: [0.3, 0.7, 0.3]
 243 |               } : {
 244 |                 y: 0,
 245 |                 opacity: 0
 246 |               }}
 247 |               transition={{
 248 |                 duration: particle.duration,
 249 |                 repeat: isCardReady ? Infinity : 0,
 250 |                 delay: isCardReady ? 2.0 + particle.delay : 0
 251 |               }}
 252 |             />
 253 |           ))}
 254 |                 </div>
 255 |               </div>
 256 |             </div>
 257 | 
 258 |             {/* Back Side - Book of Answers */}
 259 |             <div className="star-card-face star-card-back">
 260 |               <div className="star-card-content flex flex-col h-full">
 261 |                 {/* 标题 */}
 262 |                 <motion.div
 263 |                   initial={{ opacity: 0, y: -10 }}
 264 |                   animate={{ opacity: 1, y: 0 }}
 265 |                   transition={{ delay: 0.2 }}
 266 |                 >
 267 |                   <h3 className="answer-label text-xl font-semibold text-cosmic-accent text-center mb-6">来自宇宙的答案</h3>
 268 |                 </motion.div>
 269 |                 
 270 |                 {/* 答案部分 - 居中显示 */}
 271 |                 <div className="answer-section flex-grow flex items-center justify-center px-6">
 272 |                   <motion.div
 273 |                     className="answer-reveal text-center"
 274 |                     initial={{ opacity: 0, scale: 0.9 }}
 275 |                     animate={{ opacity: 1, scale: 1 }}
 276 |                     transition={{ delay: 0.4, type: "spring", damping: 20 }}
 277 |                   >
 278 |                     <p className="answer-text text-3xl font-bold text-white mb-2 drop-shadow-[0_0_8px_rgba(255,255,255,0.3)]">{bookAnswer}</p>
 279 |                   </motion.div>
 280 |                 </div>
 281 |                 
 282 |                 {/* 附言部分 - 放在底部，进一步降低视觉重要性 */}
 283 |                 <motion.div
 284 |                   className="reflection-section mt-auto mb-3 px-4"
 285 |                   initial={{ opacity: 0 }}
 286 |                   animate={{ 
 287 |                     opacity: 1 
 288 |                   }}
 289 |                   transition={{ delay: 0.6 }}
 290 |                 >
 291 |                   <p className="reflection-text text-[9px] text-neutral-400 italic text-center leading-tight tracking-wide">{answerReflection}</p>
 292 |                 </motion.div>
 293 |                 
 294 |                 {/* 抽屉式输入框 - 直接显示，无需点击按钮 */}
 295 |                 <motion.div
 296 |                   className="card-footer"
 297 |                   initial={{ opacity: 0 }}
 298 |                   animate={{ opacity: 1 }}
 299 |                   transition={{ delay: 0.7 }}
 300 |                 >
 301 |                   <motion.div 
 302 |                     className="input-ghost-wrapper w-full"
 303 |                     initial={{ y: 20, opacity: 0 }}
 304 |                     animate={{ y: 0, opacity: 1 }}
 305 |                     transition={{ type: "spring", damping: 20, delay: 0.7 }}
 306 |                   >
 307 |                     <div className="flex items-center gap-3 relative py-2 px-1">
 308 |                       <input
 309 |                         ref={inputRef}
 310 |                         type="text"
 311 |                         className="flex-1 bg-transparent text-white placeholder-neutral-400 outline-none text-sm leading-relaxed border-0 border-b border-neutral-600/50 focus:border-cosmic-accent transition-colors duration-300"
 312 |                         placeholder="说说你的困惑吧"
 313 |                         value={inputValue}
 314 |                         onChange={(e) => setInputValue(e.target.value)}
 315 |                         onKeyPress={handleKeyPress}
 316 |                         onClick={(e) => e.stopPropagation()} // 只有输入框本身阻止传播
 317 |                       />
 318 |                       <motion.button
 319 |                         className={`w-7 h-7 rounded-full flex items-center justify-center transition-colors ${
 320 |                           inputValue.trim() ? 'bg-cosmic-accent/80 text-white' : 'bg-transparent text-neutral-400'
 321 |                         }`}
 322 |                         onClick={(e) => {
 323 |                           e.stopPropagation(); // 只有按钮本身阻止传播
 324 |                           handleSendMessage();
 325 |                         }}
 326 |                         disabled={!inputValue.trim()}
 327 |                         whileHover={inputValue.trim() ? { scale: 1.1 } : {}}
 328 |                         whileTap={inputValue.trim() ? { scale: 0.95 } : {}}
 329 |                       >
 330 |                         <StarRayIcon size={14} animated={!!inputValue.trim()} />
 331 |                       </motion.button>
 332 |                     </div>
 333 |                   </motion.div>
 334 |                 </motion.div>
 335 |               </div>
 336 |             </div>
 337 |           </motion.div>
 338 |           
 339 |           {/* Hover glow effect */}
 340 |           <motion.div
 341 |             className="star-card-glow"
 342 |             animate={{
 343 |               opacity: 0.4,
 344 |               scale: 1.05,
 345 |             }}
 346 |             transition={{ duration: 0.3 }}
 347 |           />
 348 |         </div>
 349 |       </motion.div>
 350 |     </motion.div>,
 351 |     document.body
 352 |   );
 353 | };
 354 | 
 355 | export default InspirationCard;

```

`staroracle-app_allreact/src/components/LoadingMessage.tsx`:

```tsx
   1 | import React from 'react';
   2 | 
   3 | const LoadingMessage: React.FC = () => {
   4 |   return (
   5 |     <div className="flex justify-start mb-4">
   6 |       <div className="text-white py-2 max-w-[80%]">
   7 |         <div className="flex items-center gap-1">
   8 |           <div 
   9 |             className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
  10 |             style={{ animationDelay: '0ms' }}
  11 |           ></div>
  12 |           <div 
  13 |             className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
  14 |             style={{ animationDelay: '150ms' }}
  15 |           ></div>
  16 |           <div 
  17 |             className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"
  18 |             style={{ animationDelay: '300ms' }}
  19 |           ></div>
  20 |         </div>
  21 |       </div>
  22 |     </div>
  23 |   );
  24 | };
  25 | 
  26 | export default LoadingMessage;

```

`staroracle-app_allreact/src/components/MessageContextMenu.tsx`:

```tsx
   1 | import React, { useState, useEffect, useRef } from 'react';
   2 | import { Copy, Download, Share } from 'lucide-react';
   3 | 
   4 | interface MessageContextMenuProps {
   5 |   isVisible: boolean;
   6 |   position: { x: number; y: number };
   7 |   messageText: string;
   8 |   onClose: () => void;
   9 |   onCopy: () => void;
  10 | }
  11 | 
  12 | const MessageContextMenu: React.FC<MessageContextMenuProps> = ({
  13 |   isVisible,
  14 |   position,
  15 |   messageText,
  16 |   onClose,
  17 |   onCopy
  18 | }) => {
  19 |   const menuRef = useRef<HTMLDivElement>(null);
  20 | 
  21 |   // 点击外部关闭菜单
  22 |   useEffect(() => {
  23 |     const handleClickOutside = (event: MouseEvent) => {
  24 |       if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
  25 |         onClose();
  26 |       }
  27 |     };
  28 | 
  29 |     if (isVisible) {
  30 |       document.addEventListener('mousedown', handleClickOutside);
  31 |       document.addEventListener('touchstart', handleClickOutside);
  32 |     }
  33 | 
  34 |     return () => {
  35 |       document.removeEventListener('mousedown', handleClickOutside);
  36 |       document.removeEventListener('touchstart', handleClickOutside);
  37 |     };
  38 |   }, [isVisible, onClose]);
  39 | 
  40 |   if (!isVisible) return null;
  41 | 
  42 |   const handleCopyClick = () => {
  43 |     onCopy();
  44 |     onClose();
  45 |   };
  46 | 
  47 |   const handleSelectText = () => {
  48 |     // 临时创建一个可选择的元素来复制文本
  49 |     const textArea = document.createElement('textarea');
  50 |     textArea.value = messageText;
  51 |     document.body.appendChild(textArea);
  52 |     textArea.select();
  53 |     document.execCommand('copy');
  54 |     document.body.removeChild(textArea);
  55 |     onClose();
  56 |   };
  57 | 
  58 |   return (
  59 |     <>
  60 |       {/* 背景遮罩 */}
  61 |       <div className="fixed inset-0 z-[9999] bg-black bg-opacity-20" />
  62 |       
  63 |       {/* 菜单内容 */}
  64 |       <div
  65 |         ref={menuRef}
  66 |         className="fixed z-[10000] bg-gray-800 rounded-lg shadow-2xl border border-gray-600 py-2 min-w-[180px]"
  67 |         style={{
  68 |           left: Math.min(position.x, window.innerWidth - 200),
  69 |           top: Math.max(20, Math.min(position.y, window.innerHeight - 150)),
  70 |         }}
  71 |       >
  72 |         <button
  73 |           onClick={handleSelectText}
  74 |           className="flex items-center gap-3 w-full px-4 py-3 text-left text-white hover:bg-gray-700 transition-colors stellar-body"
  75 |         >
  76 |           <Copy className="w-4 h-4" />
  77 |           复制文本
  78 |         </button>
  79 |         
  80 |         <button
  81 |           onClick={handleCopyClick}
  82 |           className="flex items-center gap-3 w-full px-4 py-3 text-left text-white hover:bg-gray-700 transition-colors stellar-body"
  83 |         >
  84 |           <Download className="w-4 h-4" />
  85 |           复制消息
  86 |         </button>
  87 |         
  88 |         <button
  89 |           onClick={() => {
  90 |             // TODO: 实现分享功能
  91 |             onClose();
  92 |           }}
  93 |           className="flex items-center gap-3 w-full px-4 py-3 text-left text-gray-400 hover:bg-gray-700 transition-colors stellar-body"
  94 |         >
  95 |           <Share className="w-4 h-4" />
  96 |           分享 (待实现)
  97 |         </button>
  98 |       </div>
  99 |     </>
 100 |   );
 101 | };
 102 | 
 103 | export default MessageContextMenu;

```

`staroracle-app_allreact/src/components/OracleInput.tsx`:

```tsx
   1 | import React, { useState, useEffect } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { Mic } from 'lucide-react';
   5 | import { useStarStore } from '../store/useStarStore';
   6 | import { playSound } from '../utils/soundUtils';
   7 | import StarRayIcon from './StarRayIcon';
   8 | 
   9 | // iOS设备检测
  10 | const isIOS = () => {
  11 |   return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
  12 |          (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  13 | };
  14 | 
  15 | const OracleInput: React.FC = () => {
  16 |   const { isAsking, setIsAsking, addStar, pendingStarPosition, isLoading } = useStarStore();
  17 |   const [question, setQuestion] = useState('');
  18 |   const [isRecording, setIsRecording] = useState(false);
  19 |   const [starAnimated, setStarAnimated] = useState(false);
  20 |   const [keyboardHeight, setKeyboardHeight] = useState(0);
  21 |   const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);
  22 |   
  23 |   const handleCloseInput = () => {
  24 |     if (!isLoading) {
  25 |       setIsAsking(false);
  26 |     }
  27 |   };
  28 |   
  29 |   const handleMicClick = () => {
  30 |     setIsRecording(!isRecording);
  31 |     console.log('Microphone clicked, recording:', !isRecording);
  32 |     // TODO: 集成语音识别功能
  33 |   };
  34 | 
  35 |   const handleStarClick = () => {
  36 |     setStarAnimated(true);
  37 |     console.log('Star ray button clicked');
  38 |     
  39 |     // 如果有输入内容，直接提交
  40 |     if (question.trim()) {
  41 |       // 创建一个模拟的表单事件
  42 |       const fakeEvent = {
  43 |         preventDefault: () => {},
  44 |       } as React.FormEvent;
  45 |       handleSubmit(fakeEvent);
  46 |     }
  47 |     
  48 |     // Reset animation after completion
  49 |     setTimeout(() => {
  50 |       setStarAnimated(false);
  51 |     }, 1000);
  52 |   };
  53 | 
  54 |   const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  55 |     setQuestion(e.target.value);
  56 |   };
  57 | 
  58 |   const handleKeyPress = (e: React.KeyboardEvent) => {
  59 |     if (e.key === 'Enter') {
  60 |       handleSubmit(e as any);
  61 |     }
  62 |   };
  63 |   
  64 |   // iOS键盘监听和视口调整
  65 |   useEffect(() => {
  66 |     if (!isIOS() || !isAsking) return;
  67 | 
  68 |     const handleViewportChange = () => {
  69 |       const viewport = window.visualViewport;
  70 |       if (viewport) {
  71 |         const keyboardHeight = window.innerHeight - viewport.height;
  72 |         const isVisible = keyboardHeight > 0;
  73 |         
  74 |         setKeyboardHeight(keyboardHeight);
  75 |         setIsKeyboardVisible(isVisible);
  76 |       }
  77 |     };
  78 | 
  79 |     // 监听视口变化
  80 |     if (window.visualViewport) {
  81 |       window.visualViewport.addEventListener('resize', handleViewportChange);
  82 |       return () => {
  83 |         window.visualViewport?.removeEventListener('resize', handleViewportChange);
  84 |       };
  85 |     } else {
  86 |       // 备用方案
  87 |       let initialHeight = window.innerHeight;
  88 |       const handleResize = () => {
  89 |         const currentHeight = window.innerHeight;
  90 |         const keyboardHeight = Math.max(0, initialHeight - currentHeight);
  91 |         const isVisible = keyboardHeight > 100;
  92 |         
  93 |         setKeyboardHeight(keyboardHeight);
  94 |         setIsKeyboardVisible(isVisible);
  95 |       };
  96 |       
  97 |       window.addEventListener('resize', handleResize);
  98 |       return () => window.removeEventListener('resize', handleResize);
  99 |     }
 100 |   }, [isAsking]);
 101 |   
 102 |   // iOS专用的输入框点击处理
 103 |   const handleInputClick = (e: React.MouseEvent<HTMLInputElement>) => {
 104 |     if (isIOS()) {
 105 |       const input = e.target as HTMLInputElement;
 106 |       // 确保iOS键盘弹起
 107 |       input.focus();
 108 |       // 设置光标到末尾
 109 |       setTimeout(() => {
 110 |         const length = input.value.length;
 111 |         input.setSelectionRange(length, length);
 112 |       }, 100);
 113 |     }
 114 |   };
 115 |   
 116 |   // 计算模态框的动态样式
 117 |   const getModalStyle = () => {
 118 |     if (isIOS() && isKeyboardVisible && keyboardHeight > 0) {
 119 |       // 键盘弹起时，将模态框向上移动
 120 |       return {
 121 |         transform: `translateY(-${keyboardHeight / 2}px)`,
 122 |         transition: 'transform 0.25s ease-out'
 123 |       };
 124 |     }
 125 |     return {
 126 |       transform: 'translateY(0)',
 127 |       transition: 'transform 0.25s ease-out'
 128 |     };
 129 |   };
 130 |   
 131 |   const handleSubmit = async (e: React.FormEvent) => {
 132 |     e.preventDefault();
 133 |     
 134 |     if (!question.trim() || isLoading) return;
 135 |     
 136 |     playSound('starLight');
 137 |     
 138 |     try {
 139 |       // Close the input modal immediately
 140 |       setIsAsking(false);
 141 |       
 142 |       // Add the star (this will trigger the loading animation)
 143 |       await addStar(question);
 144 |       
 145 |       setQuestion('');
 146 |       setTimeout(() => {
 147 |         playSound('starReveal');
 148 |       }, 1000);
 149 |     } catch (error) {
 150 |       console.error('Error creating star:', error);
 151 |     }
 152 |   };
 153 |   
 154 |   return (
 155 |     <>
 156 |       {/* Question input modal with new dark input bar design */}
 157 |       {createPortal(
 158 |         <AnimatePresence>
 159 |           {isAsking && (
 160 |             <motion.div
 161 |               className="fixed inset-0 flex items-center justify-center"
 162 |               style={{ zIndex: 999999 }}
 163 |               initial={{ opacity: 0 }}
 164 |               animate={{ opacity: 1 }}
 165 |               exit={{ opacity: 0 }}
 166 |             >
 167 |               <motion.div
 168 |                 className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
 169 |                 initial={{ opacity: 0 }}
 170 |                 animate={{ opacity: 1 }}
 171 |                 exit={{ opacity: 0 }}
 172 |                 onClick={handleCloseInput}
 173 |               />
 174 |               
 175 |               <motion.div
 176 |                 className="w-full max-w-md mx-4 z-10"
 177 |                 initial={{ opacity: 0, y: 20 }}
 178 |                 animate={{ opacity: 1, y: 0 }}
 179 |                 exit={{ opacity: 0, y: 20 }}
 180 |                 style={getModalStyle()}
 181 |               >
 182 |                 {/* Title */}
 183 |                 <h2 className="stellar-title text-white mb-6 text-center">Ask the Stars</h2>
 184 |                 
 185 |                 {/* Dark Input Bar */}
 186 |                 <form onSubmit={handleSubmit}>
 187 |                   <div className="relative">
 188 |                     {/* Main container with dark background */}
 189 |                     <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
 190 |                       
 191 |                       {/* Input field */}
 192 |                       <input
 193 |                         type="text"
 194 |                         value={question}
 195 |                         onChange={handleInputChange}
 196 |                         onKeyPress={handleKeyPress}
 197 |                         onClick={handleInputClick}
 198 |                         placeholder="What wisdom do you seek from the cosmos?"
 199 |                         className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none stellar-body"
 200 |                         autoFocus
 201 |                         disabled={isLoading}
 202 |                         // iOS专用属性确保键盘弹起
 203 |                         inputMode="text"
 204 |                         autoComplete="off"
 205 |                         autoCapitalize="sentences"
 206 |                         spellCheck="false"
 207 |                       />
 208 | 
 209 |                       {/* Right side icons container */}
 210 |                       <div className="flex items-center space-x-2 mr-3 oracle-input-buttons">
 211 |                         
 212 |                         {/* Microphone button - 使用新的CSS类解决iOS灰色背景 */}
 213 |                         <button
 214 |                           type="button"
 215 |                           onClick={handleMicClick}
 216 |                           className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
 217 |                             isRecording 
 218 |                               ? 'recording text-white' 
 219 |                               : 'text-gray-300'
 220 |                           }`}
 221 |                           disabled={isLoading}
 222 |                         >
 223 |                           <Mic className="w-4 h-4" strokeWidth={2} />
 224 |                         </button>
 225 | 
 226 |                         {/* Star ray submit button - 使用新的CSS类解决iOS灰色背景 */}
 227 |                         <motion.button
 228 |                           type="button"
 229 |                           onClick={handleStarClick}
 230 |                           className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
 231 |                             question.trim() 
 232 |                               ? 'text-cosmic-accent' 
 233 |                               : 'text-gray-300'
 234 |                           }`}
 235 |                           disabled={isLoading}
 236 |                           whileHover={!isLoading ? { scale: 1.1 } : {}}
 237 |                         >
 238 |                           {isLoading ? (
 239 |                             <StarRayIcon 
 240 |                               size={16} 
 241 |                               animated={true} 
 242 |                               iconColor="#ffffff"
 243 |                             />
 244 |                           ) : (
 245 |                             <StarRayIcon 
 246 |                               size={16} 
 247 |                               animated={starAnimated || !!question.trim()} 
 248 |                               iconColor={question.trim() ? "#9333ea" : "#ffffff"}
 249 |                             />
 250 |                           )}
 251 |                         </motion.button>
 252 |                         
 253 |                       </div>
 254 |                     </div>
 255 | 
 256 |                     {/* Recording indicator */}
 257 |                     {isRecording && (
 258 |                       <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
 259 |                         <div className="flex items-center space-x-2 text-red-400 text-xs">
 260 |                           <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
 261 |                           <span>Recording...</span>
 262 |                         </div>
 263 |                       </div>
 264 |                     )}
 265 |                   </div>
 266 |                 </form>
 267 | 
 268 |                 {/* Cancel button */}
 269 |                 <div className="flex justify-center mt-6">
 270 |                   <button
 271 |                     type="button"
 272 |                     className="cosmic-button px-6 py-2 rounded-full text-white text-sm"
 273 |                     onClick={handleCloseInput}
 274 |                     disabled={isLoading}
 275 |                   >
 276 |                     Cancel
 277 |                   </button>
 278 |                 </div>
 279 |               </motion.div>
 280 |             </motion.div>
 281 |           )}
 282 |         </AnimatePresence>,
 283 |         document.body
 284 |       )}
 285 |       
 286 |       {/* Loading animation where the star will appear - keep original */}
 287 |       <AnimatePresence>
 288 |         {isLoading && pendingStarPosition && (
 289 |           <motion.div 
 290 |             className="absolute z-20 pointer-events-none"
 291 |             style={{ 
 292 |               left: `${pendingStarPosition.x}%`, 
 293 |               top: `${pendingStarPosition.y}%`,
 294 |               transform: 'translate(-50%, -50%)'
 295 |             }}
 296 |             initial={{ opacity: 0, scale: 0.5 }}
 297 |             animate={{ opacity: 1, scale: 1 }}
 298 |             exit={{ opacity: 0 }}
 299 |           >
 300 |             <div className="w-12 h-12 flex items-center justify-center">
 301 |               <StarRayIcon size={48} animated={true} className="text-cosmic-accent animate-pulse" />
 302 |             </div>
 303 |           </motion.div>
 304 |         )}
 305 |       </AnimatePresence>
 306 |     </>
 307 |   );
 308 | };
 309 | 
 310 | export default OracleInput;

```

`staroracle-app_allreact/src/components/Star.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | 
   4 | interface StarProps {
   5 |   x: number;
   6 |   y: number;
   7 |   size: number;
   8 |   brightness: number;
   9 |   isSpecial: boolean;
  10 |   isActive: boolean;
  11 |   isGrowing?: boolean;
  12 |   onClick: () => void;
  13 |   tags?: string[];
  14 |   category?: string;
  15 |   connectionCount?: number;
  16 | }
  17 | 
  18 | const Star: React.FC<StarProps> = ({
  19 |   x,
  20 |   y,
  21 |   size,
  22 |   brightness,
  23 |   isSpecial,
  24 |   isActive,
  25 |   isGrowing = false,
  26 |   onClick,
  27 |   tags = [],
  28 |   category = 'existential',
  29 |   connectionCount = 0,
  30 | }) => {
  31 |   return (
  32 |     // 1. 外部定位容器：负责精确定位在坐标系中
  33 |     <div
  34 |       style={{
  35 |         position: 'absolute',
  36 |         left: `${x}px`,
  37 |         top: `${y}px`,
  38 |         transform: 'translate(-50%, -50%)',
  39 |         // 使用Flexbox确保内部元素完美居中
  40 |         display: 'flex',
  41 |         justifyContent: 'center',
  42 |         alignItems: 'center',
  43 |         // 设置一个合理的点击区域
  44 |         width: `${size * 1.5}px`,
  45 |         height: `${size * 1.5}px`,
  46 |         cursor: 'pointer',
  47 |         zIndex: isGrowing ? 20 : 10,
  48 |       }}
  49 |       onClick={onClick}
  50 |       title={`${category.replace('_', ' ')} • ${tags.slice(0, 3).join(', ')}`}
  51 |     >
  52 |       {/* 2. 视觉元素容器：负责星星的外观和动画 */}
  53 |       <motion.div
  54 |         className={`star-container ${isActive ? 'pulse' : ''} ${isSpecial ? 'special twinkle' : ''}`}
  55 |         initial={{ opacity: 0, scale: 0 }}
  56 |         animate={{ 
  57 |           opacity: isGrowing ? 1 : brightness,
  58 |           scale: isGrowing ? 2 : 1,
  59 |         }}
  60 |         whileHover={{ scale: isGrowing ? 2 : 1.5, opacity: 1 }}
  61 |         whileTap={{ scale: 0.9 }}
  62 |         style={{
  63 |           width: `${size}px`,
  64 |           height: `${size}px`,
  65 |           display: 'flex',
  66 |           justifyContent: 'center',
  67 |           alignItems: 'center',
  68 |         }}
  69 |       >
  70 |         {/* 3. 星星核心：实际的星星视觉效果 */}
  71 |         <motion.div
  72 |           className="star-core"
  73 |           style={{
  74 |             width: '100%',
  75 |             height: '100%',
  76 |             backgroundColor: '#fff',
  77 |             borderRadius: '50%',
  78 |             filter: isActive ? 'blur(0)' : 'blur(1px)',
  79 |           }}
  80 |         />
  81 |         
  82 |         {/* 4. 星星辐射线：仅在增长状态显示 */}
  83 |         {isGrowing && (
  84 |           <svg
  85 |             className="star-lines"
  86 |             style={{
  87 |               position: 'absolute',
  88 |               top: '50%',
  89 |               left: '50%',
  90 |               transform: 'translate(-50%, -50%)',
  91 |               width: '200%',
  92 |               height: '200%',
  93 |             }}
  94 |           >
  95 |             {[0, 1, 2, 3].map((i) => (
  96 |               <motion.line
  97 |                 key={i}
  98 |                 x1="50%"
  99 |                 y1="50%"
 100 |                 x2={`${50 + Math.cos(i * Math.PI / 2) * 40}%`}
 101 |                 y2={`${50 + Math.sin(i * Math.PI / 2) * 40}%`}
 102 |                 stroke="#fff"
 103 |                 strokeWidth="1"
 104 |                 initial={{ pathLength: 0, opacity: 0 }}
 105 |                 animate={{ 
 106 |                   pathLength: 1,
 107 |                   opacity: [0, 0.8, 0],
 108 |                 }}
 109 |                 transition={{
 110 |                   duration: 1.5,
 111 |                   delay: i * 0.2,
 112 |                   repeat: Infinity,
 113 |                   repeatDelay: 1,
 114 |                 }}
 115 |               />
 116 |             ))}
 117 |           </svg>
 118 |         )}
 119 |       </motion.div>
 120 |     </div>
 121 |   );
 122 | };
 123 | 
 124 | export default Star;

```

`staroracle-app_allreact/src/components/StarCard.tsx`:

```tsx
   1 | import React, { useState, useMemo, useEffect, useRef } from 'react';
   2 | import { motion } from 'framer-motion';
   3 | import { Calendar, Heart } from 'lucide-react';
   4 | import { Star as IStar } from '../types';
   5 | import { useStarStore } from '../store/useStarStore';
   6 | import { playSound } from '../utils/soundUtils';
   7 | import StarRayIcon from './StarRayIcon';
   8 | 
   9 | // 星星样式类型
  10 | const STAR_STYLES = {
  11 |   STANDARD: 'standard', // 标准8条光芒
  12 |   CROSS: 'cross',       // 十字形
  13 |   BURST: 'burst',       // 爆发式
  14 |   SPARKLE: 'sparkle',   // 闪烁式
  15 |   RINGED: 'ringed',     // 带环星
  16 |   // 行星样式
  17 |   PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  18 |   PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  19 |   PLANET_SEAS: 'planet_seas',       // 海洋行星
  20 |   PLANET_DUST: 'planet_dust',       // 尘埃行星
  21 |   PLANET_RINGS: 'planet_rings'      // 带环行星
  22 | };
  23 | 
  24 | // 宇宙色彩主题
  25 | const COSMIC_PALETTES = [
  26 |   { 
  27 |     name: '深空蓝', 
  28 |     inner: 'hsl(250, 40%, 20%)', 
  29 |     outer: 'hsl(230, 50%, 5%)',
  30 |     star: 'hsl(220, 100%, 85%)',
  31 |     accent: 'hsl(240, 70%, 70%)'
  32 |   },
  33 |   { 
  34 |     name: '星云紫', 
  35 |     inner: 'hsl(280, 50%, 18%)', 
  36 |     outer: 'hsl(260, 60%, 4%)',
  37 |     star: 'hsl(290, 100%, 85%)',
  38 |     accent: 'hsl(280, 70%, 70%)'
  39 |   },
  40 |   { 
  41 |     name: '远古红', 
  42 |     inner: 'hsl(340, 45%, 15%)', 
  43 |     outer: 'hsl(320, 50%, 5%)',
  44 |     star: 'hsl(350, 100%, 85%)',
  45 |     accent: 'hsl(340, 70%, 70%)'
  46 |   },
  47 |   { 
  48 |     name: '冰晶蓝', 
  49 |     inner: 'hsl(200, 50%, 15%)', 
  50 |     outer: 'hsl(220, 60%, 6%)',
  51 |     star: 'hsl(190, 100%, 85%)',
  52 |     accent: 'hsl(200, 70%, 70%)'
  53 |   }
  54 | ];
  55 | 
  56 | interface StarCardProps {
  57 |   star: IStar;
  58 |   isFlipped?: boolean;
  59 |   onFlip?: () => void;
  60 |   showActions?: boolean;
  61 |   starStyle?: string; // 可选的星星样式
  62 |   colorTheme?: number; // 可选的颜色主题索引
  63 |   onContextMenu?: (e: React.MouseEvent) => void; // 右键菜单回调
  64 | }
  65 | 
  66 | const StarCard: React.FC<StarCardProps> = ({ 
  67 |   star, 
  68 |   isFlipped = false, 
  69 |   onFlip,
  70 |   showActions = true,
  71 |   starStyle,
  72 |   colorTheme,
  73 |   onContextMenu
  74 | }) => {
  75 |   const [isHovered, setIsHovered] = useState(false);
  76 |   const planetCanvasRef = useRef<HTMLCanvasElement>(null);
  77 |   
  78 |   // 为每个星星确定一个稳定的样式和颜色主题
  79 |   const { style, theme, hasRing, dustCount } = useMemo(() => {
  80 |     // 使用星星ID作为随机种子，确保同一个星星总是有相同的样式
  81 |     const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
  82 |     const seedRandom = (min: number, max: number) => {
  83 |       const x = Math.sin(seed) * 10000;
  84 |       const r = x - Math.floor(x);
  85 |       return Math.floor(r * (max - min + 1)) + min;
  86 |     };
  87 |     
  88 |     // 获取所有可能的样式
  89 |     const allStyles = Object.values(STAR_STYLES);
  90 |     const randomStyle = starStyle || allStyles[seedRandom(0, allStyles.length - 1)];
  91 |     const randomTheme = colorTheme !== undefined ? colorTheme : seedRandom(0, 3);
  92 |     const randomHasRing = star.isSpecial ? (seedRandom(0, 10) > 6) : false;
  93 |     const randomDustCount = seedRandom(5, star.isSpecial ? 20 : 10);
  94 |     
  95 |     return {
  96 |       style: randomStyle,
  97 |       theme: randomTheme,
  98 |       hasRing: randomHasRing,
  99 |       dustCount: randomDustCount
 100 |     };
 101 |   }, [star.id, star.isSpecial, starStyle, colorTheme]);
 102 |   
 103 |   // 获取当前颜色主题
 104 |   const currentTheme = COSMIC_PALETTES[theme];
 105 |   
 106 |   // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
 107 |   const starColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
 108 |   
 109 |   // 随机生成尘埃粒子
 110 |   const dustParticles = useMemo(() => {
 111 |     return Array.from({ length: dustCount }).map((_, i) => {
 112 |       const angle = Math.random() * Math.PI * 2;
 113 |       const distance = 30 + Math.random() * 40;
 114 |       return {
 115 |         id: i,
 116 |         x: 100 + Math.cos(angle) * distance,
 117 |         y: 100 + Math.sin(angle) * distance,
 118 |         size: Math.random() * 1.5 + 0.5,
 119 |         opacity: Math.random() * 0.7 + 0.3,
 120 |         animationDuration: 2 + Math.random() * 3
 121 |       };
 122 |     });
 123 |   }, [dustCount]);
 124 |   
 125 |   // 生成星环配置（如果有）
 126 |   const ringConfig = useMemo(() => {
 127 |     if (!hasRing) return null;
 128 |     
 129 |     const ringTilt = (Math.random() - 0.5) * 0.8;
 130 |     return {
 131 |       tilt: ringTilt,
 132 |       radiusX: 25,
 133 |       radiusY: 25 * 0.35,
 134 |       color: starColor,
 135 |       lineWidth: 1.5
 136 |     };
 137 |   }, [hasRing, starColor]);
 138 | 
 139 |   // 处理右键点击，显示灵感卡片
 140 |   const handleContextMenu = (e: React.MouseEvent) => {
 141 |     e.preventDefault();
 142 |     if (onContextMenu) {
 143 |       onContextMenu(e);
 144 |     }
 145 |   };
 146 | 
 147 |   // 行星绘制函数 - 从star-plantegenerate.html移植
 148 |   useEffect(() => {
 149 |     // 只有当样式是行星类型且canvas存在时绘制行星
 150 |     if (!style.startsWith('planet_') || !planetCanvasRef.current) return;
 151 |     
 152 |     const canvas = planetCanvasRef.current;
 153 |     const ctx = canvas.getContext('2d');
 154 |     if (!ctx) return;
 155 |     
 156 |     // 设置canvas尺寸 - 提高分辨率，解决模糊和锯齿问题
 157 |     const scale = window.devicePixelRatio || 2; // 使用设备像素比或至少2倍
 158 |     canvas.width = 200 * scale;
 159 |     canvas.height = 200 * scale;
 160 |     ctx.scale(scale, scale); // 缩放上下文以匹配更高的分辨率
 161 |     
 162 |     // 启用抗锯齿
 163 |     ctx.imageSmoothingEnabled = true;
 164 |     ctx.imageSmoothingQuality = 'high';
 165 |     
 166 |     // 使用星星ID作为随机种子
 167 |     const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
 168 |     const seedRandom = (min: number, max: number) => {
 169 |       const x = Math.sin(seed) * 10000;
 170 |       const r = x - Math.floor(x);
 171 |       return Math.floor(r * (max - min + 1)) + min;
 172 |     };
 173 |     
 174 |     // 星球绘制工具函数
 175 |     const drawPlanet = () => {
 176 |       try {
 177 |         // 清空画布
 178 |         ctx.clearRect(0, 0, 200, 200); // 注意：这里使用逻辑尺寸200x200
 179 |         
 180 |         // 背景为透明
 181 |         ctx.fillStyle = 'rgba(0,0,0,0)';
 182 |         ctx.fillRect(0, 0, 200, 200);
 183 |         
 184 |         // 使用与星星相同的色系逻辑
 185 |         // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
 186 |         const planetBaseColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
 187 |         
 188 |         // 解析HSL颜色值以获取色相、饱和度和亮度
 189 |         let hue = 0, saturation = 0, lightness = 70;
 190 |         
 191 |         try {
 192 |           const hslMatch = planetBaseColor.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/);
 193 |           if (hslMatch && hslMatch.length >= 4) {
 194 |             hue = parseInt(hslMatch[1]);
 195 |             saturation = parseInt(hslMatch[2]);
 196 |             lightness = parseInt(hslMatch[3]);
 197 |           }
 198 |         } catch (e) {
 199 |           console.error('HSL解析错误:', e);
 200 |           // 使用默认值
 201 |           hue = 0;
 202 |           saturation = 0;
 203 |           lightness = 70;
 204 |         }
 205 |         
 206 |         // 为行星创建自己的色系，基于星星的颜色
 207 |         const baseLightness = Math.max(40, lightness - 20); // 比星星暗一些
 208 |         const lightRange = 25 + seedRandom(0, 20);
 209 |         const darkL = baseLightness - lightRange / 2;
 210 |         const lightL = baseLightness + lightRange / 2;
 211 |         
 212 |         const palette = { 
 213 |           base: `hsl(${hue}, ${saturation * 0.7}%, ${baseLightness}%)`, 
 214 |           shadow: `hsl(${hue}, ${saturation * 0.5}%, ${darkL}%)`, 
 215 |           highlight: `hsl(${hue}, ${saturation * 0.9}%, ${lightL}%)`,
 216 |           glow: planetBaseColor
 217 |         };
 218 |         
 219 |         // 星球半径（canvas中心点为100,100）- 缩小到原来的一半
 220 |         const planetRadius = (15 + seedRandom(0, 5)); // 原来是30+seedRandom(0,10)
 221 |         const planetX = 100; // 保持在中心位置
 222 |         const planetY = 100;
 223 |         
 224 |         // 星球配置
 225 |         const planet = {
 226 |           x: planetX,
 227 |           y: planetY,
 228 |           radius: planetRadius,
 229 |           palette: palette,
 230 |           shading: {
 231 |             lightAngle: seedRandom(0, 628) / 100, // 0 to 2π
 232 |             numBands: 5 + seedRandom(0, 5),
 233 |             darkL: darkL,
 234 |             lightL: lightL
 235 |           }
 236 |         };
 237 |         
 238 |         // 是否有行星环
 239 |         const hasPlanetRings = style === 'planet_rings' || (style.startsWith('planet_') && seedRandom(0, 10) > 7);
 240 |         const ringConfig = hasPlanetRings ? {
 241 |           tilt: (seedRandom(0, 100) - 50) / 100 * 0.8,
 242 |           radius: planetRadius * 1.6,
 243 |           color: palette.base,
 244 |           lineWidth: 1 + seedRandom(0, 1) // 减小线宽
 245 |         } : null;
 246 |         
 247 |         // 绘制小星星
 248 |         const drawStars = () => {
 249 |           ctx.save();
 250 |           for (let i = 0; i < 30; i++) {
 251 |             const x = Math.random() * 200;
 252 |             const y = Math.random() * 200;
 253 |             const size = Math.random() * 1.2 + 0.3; // 稍微减小星星大小
 254 |             ctx.fillStyle = '#ffffff';
 255 |             ctx.globalAlpha = Math.random() * 0.7 + 0.1;
 256 |             ctx.fillRect(x, y, size, size);
 257 |           }
 258 |           ctx.restore();
 259 |         };
 260 |         
 261 |         // 绘制行星光晕 - 参考放射状星星的中心光晕
 262 |         const drawPlanetGlow = () => {
 263 |           try {
 264 |             ctx.save();
 265 |             
 266 |             // 创建径向渐变
 267 |             const gradient = ctx.createRadialGradient(
 268 |               planet.x, planet.y, planet.radius * 0.8,
 269 |               planet.x, planet.y, planet.radius * 3
 270 |             );
 271 |             
 272 |             // 设置渐变颜色 - 修复可能的颜色格式问题
 273 |             const safeGlowColor = palette.glow || 'rgba(255,255,255,0.7)';
 274 |             gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.7)').replace('rgb', 'rgba')); // 半透明
 275 |             gradient.addColorStop(0.5, safeGlowColor.replace(')', ', 0.3)').replace('rgb', 'rgba')); // 更透明
 276 |             gradient.addColorStop(1, 'rgba(0,0,0,0)'); // 完全透明
 277 |             
 278 |             // 绘制光晕
 279 |             ctx.globalCompositeOperation = 'screen'; // 使用screen混合模式增强发光效果
 280 |             ctx.fillStyle = gradient;
 281 |             ctx.beginPath();
 282 |             ctx.arc(planet.x, planet.y, planet.radius * 3, 0, Math.PI * 2);
 283 |             ctx.fill();
 284 |             
 285 |             ctx.restore();
 286 |           } catch (e) {
 287 |             console.error('绘制光晕错误:', e);
 288 |             ctx.restore();
 289 |           }
 290 |         };
 291 |         
 292 |         // 绘制星球阴影
 293 |         const drawShadow = () => {
 294 |           const lightAngle = planet.shading.lightAngle;
 295 |           const numBands = planet.shading.numBands;
 296 |           const darkL = planet.shading.darkL;
 297 |           const lightL = planet.shading.lightL;
 298 |           const lightVec = { x: Math.cos(lightAngle), y: Math.sin(lightAngle) };
 299 |           const totalOffset = planet.radius * 0.8;
 300 |           
 301 |           for (let i = 0; i < numBands; i++) {
 302 |             const t = i / (numBands - 1);
 303 |             const currentL = darkL + t * (lightL - darkL);
 304 |             const currentColor = `hsl(${hue}, ${Math.max(0, saturation - 20 + t * 20)}%, ${currentL}%)`;
 305 |             const offsetFactor = -1 + 2 * t;
 306 |             const offsetX = lightVec.x * totalOffset * offsetFactor * -0.5;
 307 |             const offsetY = lightVec.y * totalOffset * offsetFactor * -0.5;
 308 |             
 309 |             ctx.beginPath();
 310 |             ctx.arc(planet.x - offsetX, planet.y - offsetY, planet.radius, 0, Math.PI * 2);
 311 |             ctx.fillStyle = currentColor;
 312 |             ctx.fill();
 313 |           }
 314 |         };
 315 |         
 316 |         // 绘制行星环背面 - 修复椭圆比例问题
 317 |         const drawRingBack = () => {
 318 |           if (!hasPlanetRings || !ringConfig) return;
 319 |           
 320 |           ctx.save();
 321 |           ctx.translate(planet.x, planet.y);
 322 |           ctx.rotate(ringConfig.tilt);
 323 |           const radiusX = ringConfig.radius;
 324 |           const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
 325 |           
 326 |           ctx.beginPath();
 327 |           ctx.ellipse(0, 0, radiusX, radiusY, 0, Math.PI, Math.PI * 2);
 328 |           ctx.strokeStyle = palette.base;
 329 |           ctx.lineWidth = ringConfig.lineWidth;
 330 |           ctx.globalAlpha = 0.6;
 331 |           ctx.stroke();
 332 |           ctx.restore();
 333 |         };
 334 |         
 335 |         // 绘制行星环前面 - 修复椭圆比例问题
 336 |         const drawRingFront = () => {
 337 |           if (!hasPlanetRings || !ringConfig) return;
 338 |           
 339 |           ctx.save();
 340 |           ctx.translate(planet.x, planet.y);
 341 |           ctx.rotate(ringConfig.tilt);
 342 |           const radiusX = ringConfig.radius;
 343 |           const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
 344 |           
 345 |           ctx.beginPath();
 346 |           ctx.ellipse(0, 0, radiusX, radiusY, 0, 0, Math.PI);
 347 |           ctx.strokeStyle = palette.base;
 348 |           ctx.lineWidth = ringConfig.lineWidth;
 349 |           ctx.globalAlpha = 0.8;
 350 |           ctx.stroke();
 351 |           ctx.restore();
 352 |         };
 353 |         
 354 |         // 绘制尘埃
 355 |         const drawDust = () => {
 356 |           ctx.save();
 357 |           ctx.translate(planet.x, planet.y);
 358 |           ctx.beginPath();
 359 |           ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
 360 |           ctx.clip();
 361 |           
 362 |           const numDust = 10 + seedRandom(0, 10); // 减少尘埃数量
 363 |           for (let i = 0; i < numDust; i++) {
 364 |             const angle = seedRandom(0, 628) / 100;
 365 |             const distance = seedRandom(0, Math.floor(planet.radius * 100)) / 100;
 366 |             const x = Math.cos(angle) * distance;
 367 |             const y = Math.sin(angle) * distance;
 368 |             const radius = seedRandom(0, 10) / 10 + 0.3; // 减小尘埃大小
 369 |             
 370 |             ctx.beginPath();
 371 |             ctx.arc(x, y, radius, 0, 2 * Math.PI);
 372 |             ctx.fillStyle = palette.highlight;
 373 |             ctx.globalAlpha = 0.8;
 374 |             ctx.fill();
 375 |           }
 376 |           ctx.restore();
 377 |         };
 378 |         
 379 |         // 绘制陨石坑
 380 |         const drawCraters = () => {
 381 |           ctx.save();
 382 |           ctx.translate(planet.x, planet.y);
 383 |           ctx.beginPath();
 384 |           ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
 385 |           ctx.clip();
 386 |           
 387 |           const craterCount = 5 + seedRandom(0, 10); // 减少陨石坑数量
 388 |           
 389 |           for (let i = 0; i < craterCount; i++) {
 390 |             const angle = seedRandom(0, 628) / 100;
 391 |             const distance = seedRandom(0, Math.floor(planet.radius * 80)) / 100;
 392 |             const x = Math.cos(angle) * distance;
 393 |             const y = Math.sin(angle) * distance;
 394 |             const radius = (seedRandom(0, 6) / 100 + 0.01) * planet.radius;
 395 |             
 396 |             // 计算陨石坑透视效果
 397 |             const distFromPlanetCenter = Math.sqrt(x * x + y * y);
 398 |             const MIN_SQUASH = 0.1;
 399 |             const relativeDist = Math.min(distFromPlanetCenter / planet.radius, 1.0);
 400 |             const squashFactor = Math.max(MIN_SQUASH, Math.sqrt(1.0 - Math.pow(relativeDist, 2)));
 401 |             const radiusMajor = radius;
 402 |             const radiusMinor = radius * squashFactor;
 403 |             const radialAngle = Math.atan2(y, x);
 404 |             const rotation = radialAngle + Math.PI / 2;
 405 |             
 406 |             ctx.beginPath();
 407 |             ctx.ellipse(x, y, radiusMajor, radiusMinor, rotation, 0, 2 * Math.PI);
 408 |             ctx.fillStyle = seedRandom(0, 10) > 5 ? palette.shadow : palette.highlight;
 409 |             ctx.globalAlpha = 0.6;
 410 |             ctx.fill();
 411 |           }
 412 |           
 413 |           ctx.restore();
 414 |         };
 415 |         
 416 |         // 添加一些光晕射线效果
 417 |         const drawGlowRays = () => {
 418 |           if (!star.isSpecial) return; // 只为特殊星星添加射线
 419 |           
 420 |           try {
 421 |             ctx.save();
 422 |             ctx.translate(planet.x, planet.y);
 423 |             
 424 |             const rayCount = 4 + seedRandom(0, 4);
 425 |             const baseAngle = seedRandom(0, 100) / 100 * Math.PI;
 426 |             
 427 |             for (let i = 0; i < rayCount; i++) {
 428 |               const angle = baseAngle + (i * Math.PI * 2) / rayCount;
 429 |               const length = planet.radius * (2 + seedRandom(0, 20) / 10);
 430 |               
 431 |               ctx.beginPath();
 432 |               ctx.moveTo(0, 0);
 433 |               ctx.lineTo(Math.cos(angle) * length, Math.sin(angle) * length);
 434 |               
 435 |               // 创建线性渐变
 436 |               const gradient = ctx.createLinearGradient(0, 0, Math.cos(angle) * length, Math.sin(angle) * length);
 437 |               const safeGlowColor = palette.glow || 'rgba(255,255,255,0.9)';
 438 |               gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.9)').replace('rgb', 'rgba'));
 439 |               gradient.addColorStop(1, 'rgba(0,0,0,0)');
 440 |               
 441 |               ctx.strokeStyle = gradient;
 442 |               ctx.lineWidth = 1 + seedRandom(0, 10) / 10;
 443 |               ctx.globalAlpha = 0.3 + seedRandom(0, 5) / 10;
 444 |               ctx.stroke();
 445 |             }
 446 |             
 447 |             ctx.restore();
 448 |           } catch (e) {
 449 |             console.error('绘制光晕射线错误:', e);
 450 |             ctx.restore();
 451 |           }
 452 |         };
 453 |         
 454 |         // 绘制流程
 455 |         // 1. 首先绘制光晕
 456 |         drawPlanetGlow();
 457 |         
 458 |         // 2. 绘制背景星星
 459 |         drawStars();
 460 |         
 461 |         // 3. 如果有行星环，绘制背面部分
 462 |         if (hasPlanetRings) {
 463 |           drawRingBack();
 464 |         }
 465 |         
 466 |         // 4. 绘制主星球
 467 |         ctx.save();
 468 |         ctx.beginPath();
 469 |         ctx.arc(planet.x, planet.y, planet.radius, 0, 2 * Math.PI);
 470 |         ctx.clip();
 471 |         drawShadow();
 472 |         ctx.restore();
 473 |         
 474 |         // 5. 根据星球类型绘制不同特征
 475 |         if (style === STAR_STYLES.PLANET_CRATERS) {
 476 |           drawCraters();
 477 |         } else if (style === STAR_STYLES.PLANET_DUST) {
 478 |           drawDust();
 479 |         }
 480 |         
 481 |         // 6. 如果有行星环，绘制前部
 482 |         if (hasPlanetRings) {
 483 |           drawRingFront();
 484 |         }
 485 |         
 486 |         // 7. 为特殊星球添加光晕射线
 487 |         drawGlowRays();
 488 |       } catch (error) {
 489 |         console.error('行星绘制错误:', error);
 490 |       }
 491 |     };
 492 |     
 493 |     drawPlanet();
 494 |     
 495 |   }, [style, star.id, currentTheme, starColor]);
 496 | 
 497 |   return (
 498 |     <motion.div
 499 |       className="star-card-container"
 500 |       initial={{ opacity: 0, y: 20 }}
 501 |       animate={{ opacity: 1, y: 0 }}
 502 |       whileHover={{ y: -5 }}
 503 |       onHoverStart={() => setIsHovered(true)}
 504 |       onHoverEnd={() => setIsHovered(false)}
 505 |       onContextMenu={handleContextMenu}
 506 |     >
 507 |       <div className="star-card-wrapper">
 508 |         <motion.div
 509 |           className="star-card"
 510 |           animate={{ rotateY: isFlipped ? 180 : 0 }}
 511 |           transition={{ duration: 0.6, type: "spring" }}
 512 |           onClick={onFlip}
 513 |         >
 514 |           {/* Front Side - Star Design */}
 515 |           <div className="star-card-face star-card-front">
 516 |             <div 
 517 |               className="star-card-bg"
 518 |               style={{
 519 |                 background: `radial-gradient(circle, ${currentTheme.inner} 0%, ${currentTheme.outer} 100%)`
 520 |               }}
 521 |             >
 522 |               <div className="star-card-constellation">
 523 |                 {/* 渲染行星类型星星 */}
 524 |                 {style.startsWith('planet_') && (
 525 |                   <canvas 
 526 |                     ref={planetCanvasRef} 
 527 |                     width="200" 
 528 |                     height="200" 
 529 |                     className="planet-canvas"
 530 |                     style={{
 531 |                       width: '160px',
 532 |                       height: '160px'
 533 |                     }}
 534 |                   />
 535 |                 )}
 536 |                 
 537 |                 {/* 星星模式 - 仅在非行星样式时显示 */}
 538 |                 {!style.startsWith('planet_') && (
 539 |                   <svg className="constellation-svg" viewBox="0 0 200 200">
 540 |                     <defs>
 541 |                       <radialGradient id={`starGlow-${star.id}`} cx="50%" cy="50%" r="50%">
 542 |                         <stop offset="0%" stopColor={starColor} stopOpacity="0.8"/>
 543 |                         <stop offset="100%" stopColor={starColor} stopOpacity="0"/>
 544 |                       </radialGradient>
 545 |                       
 546 |                       {/* 添加星环滤镜 */}
 547 |                       <filter id={`glow-${star.id}`} x="-50%" y="-50%" width="200%" height="200%">
 548 |                         <feGaussianBlur stdDeviation="2" result="blur" />
 549 |                         <feComposite in="SourceGraphic" in2="blur" operator="over" />
 550 |                       </filter>
 551 |                     </defs>
 552 |                     
 553 |                     {/* 背景星星 */}
 554 |                     {Array.from({ length: 20 }).map((_, i) => (
 555 |                       <motion.circle
 556 |                         key={`bg-star-${i}`}
 557 |                         cx={20 + (i % 5) * 40 + Math.random() * 20}
 558 |                         cy={20 + Math.floor(i / 5) * 40 + Math.random() * 20}
 559 |                         r={Math.random() * 1.5 + 0.5}
 560 |                         fill="rgba(255,255,255,0.6)"
 561 |                         initial={{ opacity: 0.3 }}
 562 |                         animate={{ 
 563 |                           opacity: [0.3, 0.8, 0.3],
 564 |                           scale: [1, 1.2, 1]
 565 |                         }}
 566 |                         transition={{
 567 |                           duration: 2 + Math.random() * 2,
 568 |                           repeat: Infinity,
 569 |                           delay: Math.random() * 2
 570 |                         }}
 571 |                       />
 572 |                     ))}
 573 |                     
 574 |                     {/* 尘埃粒子 */}
 575 |                     {dustParticles.map(particle => (
 576 |                       <motion.circle
 577 |                         key={`dust-${particle.id}`}
 578 |                         cx={particle.x}
 579 |                         cy={particle.y}
 580 |                         r={particle.size}
 581 |                         fill={starColor}
 582 |                         initial={{ opacity: 0 }}
 583 |                         animate={{ 
 584 |                           opacity: [0, particle.opacity, 0],
 585 |                           cx: [particle.x - 2, particle.x + 2, particle.x - 2],
 586 |                           cy: [particle.y - 2, particle.y + 2, particle.y - 2]
 587 |                         }}
 588 |                         transition={{
 589 |                           duration: particle.animationDuration,
 590 |                           repeat: Infinity,
 591 |                           ease: "easeInOut"
 592 |                         }}
 593 |                       />
 594 |                     ))}
 595 |                     
 596 |                     {/* 星环（如果有） */}
 597 |                     {hasRing && ringConfig && (
 598 |                       <>
 599 |                         {/* 背面星环 */}
 600 |                         <motion.ellipse
 601 |                           cx="100"
 602 |                           cy="100"
 603 |                           rx={ringConfig.radiusX}
 604 |                           ry={ringConfig.radiusY}
 605 |                           transform={`rotate(${ringConfig.tilt * 180 / Math.PI} 100 100)`}
 606 |                           fill="none"
 607 |                           stroke={ringConfig.color}
 608 |                           strokeWidth={ringConfig.lineWidth}
 609 |                           strokeDasharray="1,2"
 610 |                           initial={{ opacity: 0 }}
 611 |                           animate={{ 
 612 |                             opacity: [0.2, 0.5, 0.2],
 613 |                             strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
 614 |                           }}
 615 |                           transition={{
 616 |                             duration: 4,
 617 |                             repeat: Infinity,
 618 |                             ease: "easeInOut"
 619 |                           }}
 620 |                         />
 621 |                         
 622 |                         {/* 前面星环 */}
 623 |                         <motion.path
 624 |                           d={`M ${100 - ringConfig.radiusX} ${100} A ${ringConfig.radiusX} ${ringConfig.radiusY} ${ringConfig.tilt * 180 / Math.PI} 0 1 ${100 + ringConfig.radiusX} ${100}`}
 625 |                           fill="none"
 626 |                           stroke={ringConfig.color}
 627 |                           strokeWidth={ringConfig.lineWidth}
 628 |                           initial={{ opacity: 0 }}
 629 |                           animate={{ 
 630 |                             opacity: [0.5, 0.8, 0.5],
 631 |                             strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
 632 |                           }}
 633 |                           transition={{
 634 |                             duration: 3,
 635 |                             repeat: Infinity,
 636 |                             ease: "easeInOut"
 637 |                           }}
 638 |                         />
 639 |                       </>
 640 |                     )}
 641 |                     
 642 |                     {/* 主星 */}
 643 |                     <motion.circle
 644 |                       cx="100"
 645 |                       cy="100"
 646 |                       r="8"
 647 |                       fill={`url(#starGlow-${star.id})`}
 648 |                       filter={`url(#glow-${star.id})`}
 649 |                       initial={{ scale: 0 }}
 650 |                       animate={{ 
 651 |                         scale: [1, 1.1, 1],
 652 |                         opacity: [0.8, 1, 0.8]
 653 |                       }}
 654 |                       transition={{ 
 655 |                         scale: {
 656 |                           duration: 3,
 657 |                           repeat: Infinity,
 658 |                           ease: "easeInOut"
 659 |                         },
 660 |                         opacity: {
 661 |                           duration: 2,
 662 |                           repeat: Infinity,
 663 |                           ease: "easeInOut"
 664 |                         }
 665 |                       }}
 666 |                     />
 667 |                     
 668 |                     {/* 星星光芒 - 根据样式渲染不同类型 */}
 669 |                     {style === STAR_STYLES.STANDARD && (
 670 |                       // 标准8条光芒
 671 |                       [0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
 672 |                         <motion.line
 673 |                           key={`ray-${i}`}
 674 |                           x1="100"
 675 |                           y1="100"
 676 |                           x2={100 + Math.cos(i * Math.PI / 4) * 40}
 677 |                           y2={100 + Math.sin(i * Math.PI / 4) * 40}
 678 |                           stroke={starColor}
 679 |                           strokeWidth="2"
 680 |                           initial={{ pathLength: 0, opacity: 0 }}
 681 |                           animate={{ 
 682 |                             pathLength: 1,
 683 |                             opacity: [0, 0.8, 0],
 684 |                           }}
 685 |                           transition={{
 686 |                             duration: 1.5,
 687 |                             delay: i * 0.1,
 688 |                             repeat: Infinity,
 689 |                             repeatDelay: 1,
 690 |                           }}
 691 |                         />
 692 |                       ))
 693 |                     )}
 694 |                     
 695 |                     {style === STAR_STYLES.CROSS && (
 696 |                       // 十字形光芒
 697 |                       [0, 1, 2, 3].map((i) => (
 698 |                         <motion.rect
 699 |                           key={`cross-${i}`}
 700 |                           x={100 - (i % 2 === 0 ? 1 : 15)}
 701 |                           y={100 - (i % 2 === 1 ? 1 : 15)}
 702 |                           width={i % 2 === 0 ? 2 : 30}
 703 |                           height={i % 2 === 1 ? 2 : 30}
 704 |                           fill={starColor}
 705 |                           initial={{ opacity: 0, scale: 0 }}
 706 |                           animate={{ 
 707 |                             opacity: [0, 0.8, 0],
 708 |                             scale: [0, 1, 0],
 709 |                             rotate: [0, 90, 180]
 710 |                           }}
 711 |                           transition={{
 712 |                             duration: 2,
 713 |                             delay: i * 0.2,
 714 |                             repeat: Infinity,
 715 |                             repeatDelay: 0.5,
 716 |                           }}
 717 |                         />
 718 |                       ))
 719 |                     )}
 720 |                     
 721 |                     {style === STAR_STYLES.BURST && (
 722 |                       // 爆发式光芒
 723 |                       Array.from({ length: 12 }).map((_, i) => {
 724 |                         const angle = (i * Math.PI * 2) / 12;
 725 |                         const length = 20 + Math.random() * 30;
 726 |                         return (
 727 |                           <motion.line
 728 |                             key={`burst-${i}`}
 729 |                             x1="100"
 730 |                             y1="100"
 731 |                             x2={100 + Math.cos(angle) * length}
 732 |                             y2={100 + Math.sin(angle) * length}
 733 |                             stroke={starColor}
 734 |                             strokeWidth={Math.random() * 1.5 + 0.5}
 735 |                             initial={{ pathLength: 0, opacity: 0 }}
 736 |                             animate={{ 
 737 |                               pathLength: [0, 1, 0],
 738 |                               opacity: [0, 0.7, 0],
 739 |                             }}
 740 |                             transition={{
 741 |                               duration: 2 + Math.random(),
 742 |                               delay: i * 0.05,
 743 |                               repeat: Infinity,
 744 |                               repeatDelay: Math.random(),
 745 |                             }}
 746 |                           />
 747 |                         );
 748 |                       })
 749 |                     )}
 750 |                     
 751 |                     {style === STAR_STYLES.SPARKLE && (
 752 |                       // 闪烁式
 753 |                       Array.from({ length: 8 }).map((_, i) => {
 754 |                         const angle = (i * Math.PI * 2) / 8;
 755 |                         const distance = 15 + Math.random() * 20;
 756 |                         return (
 757 |                           <motion.circle
 758 |                             key={`sparkle-${i}`}
 759 |                             cx={100 + Math.cos(angle) * distance}
 760 |                             cy={100 + Math.sin(angle) * distance}
 761 |                             r={Math.random() * 2 + 1}
 762 |                             fill={starColor}
 763 |                             initial={{ opacity: 0, scale: 0 }}
 764 |                             animate={{ 
 765 |                               opacity: [0, 0.9, 0],
 766 |                               scale: [0, 1, 0]
 767 |                             }}
 768 |                             transition={{
 769 |                               duration: 1 + Math.random(),
 770 |                               delay: i * 0.1,
 771 |                               repeat: Infinity,
 772 |                               repeatDelay: Math.random() * 2,
 773 |                             }}
 774 |                           />
 775 |                         );
 776 |                       })
 777 |                     )}
 778 |                     
 779 |                     {style === STAR_STYLES.RINGED && !hasRing && (
 780 |                       // 带环星（如果没有实际环）
 781 |                       <motion.circle
 782 |                         cx="100"
 783 |                         cy="100"
 784 |                         r="15"
 785 |                         fill="none"
 786 |                         stroke={starColor}
 787 |                         strokeWidth="1"
 788 |                         strokeDasharray="1,2"
 789 |                         initial={{ opacity: 0 }}
 790 |                         animate={{ 
 791 |                           opacity: [0.3, 0.6, 0.3],
 792 |                           r: [15, 18, 15]
 793 |                         }}
 794 |                         transition={{
 795 |                           duration: 3,
 796 |                           repeat: Infinity,
 797 |                           ease: "easeInOut"
 798 |                         }}
 799 |                       />
 800 |                     )}
 801 |                   </svg>
 802 |                 )}
 803 |               </div>
 804 |               
 805 |               {/* Card title */}
 806 |               <div className="star-card-title">
 807 |                 <motion.div
 808 |                   className="star-type-badge"
 809 |                   initial={{ opacity: 0, x: -20 }}
 810 |                   animate={{ opacity: 1, x: 0 }}
 811 |                   transition={{ delay: 0.8 }}
 812 |                   style={{
 813 |                     backgroundColor: star.isSpecial ? `${currentTheme.accent}30` : 'rgba(255,255,255,0.1)'
 814 |                   }}
 815 |                 >
 816 |                   {star.isSpecial ? (
 817 |                     <>
 818 |                       <StarRayIcon className="w-3 h-3" color={currentTheme.accent} />
 819 |                       <span style={{ color: currentTheme.accent }}>Rare Celestial</span>
 820 |                     </>
 821 |                   ) : (
 822 |                     <>
 823 |                       <div className="w-3 h-3 rounded-full bg-white opacity-80" />
 824 |                       <span>Inner Star</span>
 825 |                     </>
 826 |                   )}
 827 |                 </motion.div>
 828 |                 
 829 |                 <motion.div
 830 |                   className="star-date"
 831 |                   initial={{ opacity: 0 }}
 832 |                   animate={{ opacity: 1 }}
 833 |                   transition={{ delay: 1 }}
 834 |                 >
 835 |                   <Calendar className="w-3 h-3" />
 836 |                   <span>{star.createdAt.toLocaleDateString()}</span>
 837 |                 </motion.div>
 838 |               </div>
 839 |               
 840 |               {/* Decorative elements */}
 841 |               <div className="star-card-decorations">
 842 |                 {Array.from({ length: 6 }).map((_, i) => (
 843 |                   <motion.div
 844 |                     key={i}
 845 |                     className="floating-particle"
 846 |                     style={{
 847 |                       left: `${20 + Math.random() * 60}%`,
 848 |                       top: `${20 + Math.random() * 60}%`,
 849 |                       backgroundColor: starColor,
 850 |                     }}
 851 |                     animate={{
 852 |                       y: [-5, 5, -5],
 853 |                       opacity: [0.3, 0.7, 0.3],
 854 |                     }}
 855 |                     transition={{
 856 |                       duration: 3 + Math.random() * 2,
 857 |                       repeat: Infinity,
 858 |                       delay: Math.random() * 2,
 859 |                     }}
 860 |                   />
 861 |                 ))}
 862 |               </div>
 863 |             </div>
 864 |           </div>
 865 | 
 866 |           {/* Back Side - Answer */}
 867 |           <div className="star-card-face star-card-back">
 868 |             <div className="star-card-content">
 869 |               <div className="question-section">
 870 |                 <h3 className="question-label">Your Question</h3>
 871 |                 <p className="question-text">"{star.question}"</p>
 872 |               </div>
 873 |               
 874 |               <div className="divider">
 875 |                 <StarRayIcon className="w-4 h-4 text-cosmic-accent" />
 876 |               </div>
 877 |               
 878 |               <div className="answer-section">
 879 |                 <motion.div
 880 |                   className="answer-reveal"
 881 |                   initial={{ opacity: 0, y: 20 }}
 882 |                   animate={{ opacity: 1, y: 0 }}
 883 |                   transition={{ delay: 0.3 }}
 884 |                 >
 885 |                   <h3 className="answer-label">星辰的启示</h3>
 886 |                 <p className="answer-text">{star.answer}</p>
 887 |                 </motion.div>
 888 |               </div>
 889 |               
 890 |               <motion.div
 891 |                 className="card-footer"
 892 |                 initial={{ opacity: 0 }}
 893 |                 animate={{ opacity: 1 }}
 894 |                 transition={{ delay: 0.6 }}
 895 |               >
 896 |                 <div className="star-stats">
 897 |                   <span className="stat">
 898 |                     Brightness: {Math.round(star.brightness * 100)}%
 899 |                   </span>
 900 |                   <span className="stat">
 901 |                     Size: {star.size.toFixed(1)}px
 902 |                   </span>
 903 |                 </div>
 904 |                 <p className="text-center text-sm text-cosmic-accent mt-3">
 905 |                   再次点击卡片继续探索星空
 906 |                 </p>
 907 |               </motion.div>
 908 |             </div>
 909 |           </div>
 910 |         </motion.div>
 911 |         
 912 |         {/* Hover glow effect */}
 913 |         <motion.div
 914 |           className="star-card-glow"
 915 |           animate={{
 916 |             opacity: isHovered ? 0.6 : 0,
 917 |             scale: isHovered ? 1.05 : 1,
 918 |           }}
 919 |           transition={{ duration: 0.3 }}
 920 |           style={{
 921 |             background: isHovered 
 922 |               ? `radial-gradient(circle, ${currentTheme.accent}40 0%, transparent 70%)` 
 923 |               : 'none'
 924 |           }}
 925 |         />
 926 |       </div>
 927 |       
 928 |       {/* Action buttons - only shown in collection view */}
 929 |       {showActions && (
 930 |         <motion.div
 931 |           className="star-card-actions"
 932 |           initial={{ opacity: 0 }}
 933 |           animate={{ opacity: isHovered ? 1 : 0 }}
 934 |           transition={{ duration: 0.2 }}
 935 |         >
 936 |           <button className="action-btn favorite">
 937 |             <Heart className="w-4 h-4" />
 938 |           </button>
 939 |           <button className="action-btn flip" onClick={onFlip}>
 940 |             <StarRayIcon className="w-4 h-4" />
 941 |           </button>
 942 |         </motion.div>
 943 |       )}
 944 |     </motion.div>
 945 |   );
 946 | };
 947 | 
 948 | export default StarCard;

```

`staroracle-app_allreact/src/components/StarCollection.tsx`:

```tsx
   1 | import React, { useState, useMemo, useEffect } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { X, Search, Filter, Star as StarIcon } from 'lucide-react';
   5 | import { useStarStore } from '../store/useStarStore';
   6 | import { playSound } from '../utils/soundUtils';
   7 | import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
   8 | import StarCard from './StarCard';
   9 | 
  10 | // 星星样式类型 - 与StarCard组件中的定义保持一致
  11 | const STAR_STYLES = {
  12 |   STANDARD: 'standard', // 标准8条光芒
  13 |   CROSS: 'cross',       // 十字形
  14 |   BURST: 'burst',       // 爆发式
  15 |   SPARKLE: 'sparkle',   // 闪烁式
  16 |   RINGED: 'ringed',     // 带环星
  17 |   // 行星样式
  18 |   PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  19 |   PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  20 |   PLANET_SEAS: 'planet_seas',       // 海洋行星
  21 |   PLANET_DUST: 'planet_dust',       // 尘埃行星
  22 |   PLANET_RINGS: 'planet_rings'      // 带环行星
  23 | };
  24 | 
  25 | interface StarCollectionProps {
  26 |   isOpen: boolean;
  27 |   onClose: () => void;
  28 | }
  29 | 
  30 | const StarCollection: React.FC<StarCollectionProps> = ({ isOpen, onClose }) => {
  31 |   const { constellation, drawInspirationCard } = useStarStore();
  32 |   const [searchTerm, setSearchTerm] = useState('');
  33 |   const [filterType, setFilterType] = useState<'all' | 'special' | 'recent'>('all');
  34 |   const [flippedCards, setFlippedCards] = useState<Set<string>>(new Set());
  35 |   const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  36 | 
  37 |   // 初始化iOS层级修复
  38 |   useEffect(() => {
  39 |     fixIOSZIndex();
  40 |   }, []);
  41 | 
  42 |   // 当模态框打开时隐藏其他元素
  43 |   useEffect(() => {
  44 |     if (isOpen) {
  45 |       document.body.classList.add('modal-open');
  46 |       const restore = hideOtherElements();
  47 |       setRestoreElements(() => restore);
  48 |     } else {
  49 |       document.body.classList.remove('modal-open');
  50 |       if (restoreElements) {
  51 |         restoreElements();
  52 |         setRestoreElements(null);
  53 |       }
  54 |     }
  55 |     
  56 |     return () => {
  57 |       document.body.classList.remove('modal-open');
  58 |       if (restoreElements) {
  59 |         restoreElements();
  60 |       }
  61 |     };
  62 |   }, [isOpen]);
  63 | 
  64 |   // 为每个星星生成样式映射
  65 |   const starStyleMap = useMemo(() => {
  66 |     const map = new Map();
  67 |     constellation.stars.forEach(star => {
  68 |       // 使用星星ID作为随机种子
  69 |       const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
  70 |       const seedRandom = (min: number, max: number) => {
  71 |         const x = Math.sin(seed) * 10000;
  72 |         const r = x - Math.floor(x);
  73 |         return Math.floor(r * (max - min + 1)) + min;
  74 |       };
  75 |       
  76 |       // 获取所有可能的样式
  77 |       const allStyles = Object.values(STAR_STYLES);
  78 |       // 随机选择样式和颜色主题
  79 |       const styleIndex = seedRandom(0, allStyles.length - 1);
  80 |       const colorTheme = seedRandom(0, 3);
  81 |       
  82 |       map.set(star.id, {
  83 |         style: allStyles[styleIndex],
  84 |         theme: colorTheme
  85 |       });
  86 |     });
  87 |     return map;
  88 |   }, [constellation.stars]);
  89 | 
  90 |   const handleClose = () => {
  91 |     playSound('starClick');
  92 |     onClose();
  93 |   };
  94 | 
  95 |   const handleCardFlip = (starId: string) => {
  96 |     playSound('starClick');
  97 |     setFlippedCards(prev => {
  98 |       const newSet = new Set(prev);
  99 |       if (newSet.has(starId)) {
 100 |         newSet.delete(starId);
 101 |       } else {
 102 |         newSet.add(starId);
 103 |       }
 104 |       return newSet;
 105 |     });
 106 |   };
 107 | 
 108 |   // 处理右键点击，显示灵感卡片
 109 |   const handleContextMenu = (e: React.MouseEvent) => {
 110 |     e.preventDefault();
 111 |     playSound('starReveal');
 112 |     const card = drawInspirationCard();
 113 |     console.log('📇 灵感卡片已生成:', card.question);
 114 |   };
 115 | 
 116 |   // Filter stars based on search and filter criteria
 117 |   const filteredStars = constellation.stars.filter(star => {
 118 |     const matchesSearch = star.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
 119 |                          star.answer.toLowerCase().includes(searchTerm.toLowerCase());
 120 |     
 121 |     const matchesFilter = filterType === 'all' || 
 122 |                          (filterType === 'special' && star.isSpecial) ||
 123 |                          (filterType === 'recent' && 
 124 |                           (Date.now() - star.createdAt.getTime()) < 7 * 24 * 60 * 60 * 1000);
 125 |     
 126 |     return matchesSearch && matchesFilter;
 127 |   });
 128 | 
 129 |   return createPortal(
 130 |     <AnimatePresence>
 131 |       {isOpen && (
 132 |         <motion.div
 133 |           className={getMobileModalClasses()}
 134 |           style={getMobileModalStyles()}
 135 |           initial={{ opacity: 0 }}
 136 |           animate={{ opacity: 1 }}
 137 |           exit={{ opacity: 0 }}
 138 |           onContextMenu={handleContextMenu}
 139 |         >
 140 |           {/* Backdrop */}
 141 |           <motion.div
 142 |             className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
 143 |             initial={{ opacity: 0 }}
 144 |             animate={{ opacity: 1 }}
 145 |             exit={{ opacity: 0 }}
 146 |             onClick={handleClose}
 147 |           />
 148 | 
 149 |           {/* Collection Panel */}
 150 |           <motion.div
 151 |             className="star-collection-panel"
 152 |             initial={{ opacity: 0, scale: 0.9, y: 20 }}
 153 |             animate={{ opacity: 1, scale: 1, y: 0 }}
 154 |             exit={{ opacity: 0, scale: 0.9, y: 20 }}
 155 |             transition={{ type: 'spring', damping: 25 }}
 156 |           >
 157 |             {/* Header */}
 158 |             <div className="collection-header">
 159 |               <div className="header-left">
 160 |                 {/* English: Star Collection - for future internationalization */}
 161 |                 <h2 className="stellar-title text-white">集星</h2>
 162 |                 <span className="star-count">{filteredStars.length} stars</span>
 163 |               </div>
 164 |               
 165 |               <button
 166 |                 className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
 167 |                 onClick={handleClose}
 168 |               >
 169 |                 <X className="w-5 h-5" />
 170 |               </button>
 171 |             </div>
 172 | 
 173 |             {/* Controls */}
 174 |             <div className="collection-controls">
 175 |               <div className="search-bar">
 176 |                 <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
 177 |                 <input
 178 |                   type="text"
 179 |                   placeholder="Search your stars..."
 180 |                   value={searchTerm}
 181 |                   onChange={(e) => setSearchTerm(e.target.value)}
 182 |                   className="stellar-body w-full bg-transparent text-white placeholder-gray-400 pl-10 pr-4 py-2 focus:outline-none"
 183 |                 />
 184 |               </div>
 185 |               
 186 |               <div className="control-buttons">
 187 |                 <select
 188 |                   value={filterType}
 189 |                   onChange={(e) => setFilterType(e.target.value as any)}
 190 |                   className="stellar-body bg-transparent text-white focus:outline-none p-2 rounded-full dialog-transparent-button"
 191 |                 >
 192 |                   <option value="all">All Stars</option>
 193 |                   <option value="special">Special Stars</option>
 194 |                   <option value="recent">Recent (7 days)</option>
 195 |                 </select>
 196 |               </div>
 197 |             </div>
 198 | 
 199 |             {/* Star Cards */}
 200 |             <div className="collection-content grid">
 201 |               <AnimatePresence>
 202 |                 {filteredStars.map((star, index) => {
 203 |                   const styleConfig = starStyleMap.get(star.id) || { style: 'standard', theme: 0 };
 204 |                   return (
 205 |                     <motion.div
 206 |                       key={star.id}
 207 |                       initial={{ opacity: 0, y: 20 }}
 208 |                       animate={{ opacity: 1, y: 0 }}
 209 |                       exit={{ opacity: 0, y: -20 }}
 210 |                       transition={{ delay: index * 0.1 }}
 211 |                     >
 212 |                       <StarCard
 213 |                         star={star}
 214 |                         isFlipped={flippedCards.has(star.id)}
 215 |                         onFlip={() => handleCardFlip(star.id)}
 216 |                         starStyle={styleConfig.style}
 217 |                         colorTheme={styleConfig.theme}
 218 |                         onContextMenu={handleContextMenu}
 219 |                       />
 220 |                     </motion.div>
 221 |                   );
 222 |                 })}
 223 |               </AnimatePresence>
 224 |               
 225 |               {filteredStars.length === 0 && (
 226 |                 <motion.div
 227 |                   className="empty-state"
 228 |                   initial={{ opacity: 0 }}
 229 |                   animate={{ opacity: 1 }}
 230 |                 >
 231 |                   <StarIcon className="w-12 h-12 text-gray-400 mb-4" />
 232 |                   <p className="text-gray-400">No stars found matching your criteria</p>
 233 |                 </motion.div>
 234 |               )}
 235 |             </div>
 236 |           </motion.div>
 237 |         </motion.div>
 238 |       )}
 239 |     </AnimatePresence>,
 240 |     createTopLevelContainer()
 241 |   );
 242 | };
 243 | 
 244 | export default StarCollection;

```

`staroracle-app_allreact/src/components/StarDetail.tsx`:

```tsx
   1 | import React, { useState } from 'react';
   2 | import { motion, AnimatePresence } from 'framer-motion';
   3 | import { createPortal } from 'react-dom';
   4 | import { X, Share2, Save, Tag, Heart } from 'lucide-react';
   5 | import { useStarStore } from '../store/useStarStore';
   6 | import { playSound } from '../utils/soundUtils';
   7 | import StarRayIcon from './StarRayIcon';
   8 | import { getMainTagSuggestions } from '../utils/aiTaggingUtils';
   9 | 
  10 | const StarDetail: React.FC = () => {
  11 |   const { 
  12 |     constellation, 
  13 |     activeStarId, 
  14 |     hideStarDetail,
  15 |     updateStarTags
  16 |   } = useStarStore();
  17 |   
  18 |   const activeStar = constellation.stars.find(star => star.id === activeStarId);
  19 | 
  20 |   const [editingTags, setEditingTags] = useState(false);
  21 |   const [currentTags, setCurrentTags] = useState<string[]>([]);
  22 |   const [newTag, setNewTag] = useState('');
  23 |   const [tagSuggestions, setTagSuggestions] = useState<string[]>([]);
  24 |   
  25 |   const handleClose = () => {
  26 |     playSound('starClick');
  27 |     hideStarDetail();
  28 |   };
  29 |   
  30 |   const handleShare = () => {
  31 |     playSound('starClick');
  32 |     // TODO: 实现分享功能
  33 |     console.log('分享功能将在这里实现');
  34 |   };
  35 |   
  36 |   const handleSave = () => {
  37 |     playSound('starClick');
  38 |     // TODO: 实现保存到星图功能
  39 |     console.log('保存到星图功能将在这里实现');
  40 |   };
  41 |   
  42 |   // 开始编辑标签时初始化
  43 |   const startEditingTags = () => {
  44 |     if (activeStar) {
  45 |       setCurrentTags([...activeStar.tags]);
  46 |       setEditingTags(true);
  47 |       // 根据预定义的标签系统加载建议
  48 |       setTagSuggestions(getMainTagSuggestions());
  49 |     }
  50 |   };
  51 |   
  52 |   // 保存编辑后的标签
  53 |   const saveTagChanges = () => {
  54 |     if (activeStar) {
  55 |       updateStarTags(activeStar.id, currentTags);
  56 |       setEditingTags(false);
  57 |     }
  58 |   };
  59 |   
  60 |   // 添加新标签
  61 |   const addTag = (tag: string) => {
  62 |     const normalizedTag = tag.trim().toLowerCase();
  63 |     if (normalizedTag && !currentTags.some(t => t.toLowerCase() === normalizedTag)) {
  64 |       setCurrentTags([...currentTags, normalizedTag]);
  65 |       setNewTag('');
  66 |     }
  67 |   };
  68 |   
  69 |   // 移除标签
  70 |   const removeTag = (tagToRemove: string) => {
  71 |     setCurrentTags(currentTags.filter(tag => tag !== tagToRemove));
  72 |   };
  73 |   
  74 |   // 用户输入时筛选建议
  75 |   const filterSuggestions = (input: string) => {
  76 |     const filtered = getMainTagSuggestions().filter(
  77 |       tag => tag.toLowerCase().includes(input.toLowerCase())
  78 |     );
  79 |     setTagSuggestions(filtered.slice(0, 10)); // 限制为10个建议
  80 |   };
  81 |   
  82 |   // 处理新标签输入变化
  83 |   const handleTagInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  84 |     const value = e.target.value;
  85 |     setNewTag(value);
  86 |     filterSuggestions(value);
  87 |   };
  88 |   
  89 |   const getCategoryColor = (category: string) => {
  90 |     const colors = {
  91 |       'relationships': '#FF69B4',
  92 |       'personal_growth': '#9370DB',
  93 |       'career_and_purpose': '#FFD700',  // 从'life_direction'更新
  94 |       'emotional_wellbeing': '#98FB98', // 从'wellbeing'更新
  95 |       'material': '#FFA500',
  96 |       'creative': '#FF6347',
  97 |       'philosophy_and_existence': '#87CEEB', // 从'existential'更新
  98 |       'creativity_and_passion': '#FF6347', // 添加新类别
  99 |       'daily_life': '#FFA500', // 添加新类别
 100 |     };
 101 |     return colors[category as keyof typeof colors] || '#fff';
 102 |   };
 103 |   
 104 |   if (!activeStar) return null;
 105 |   
 106 |   // 查找相连的星星
 107 |   const connectedStars = constellation.connections
 108 |     .filter(conn => conn.fromStarId === activeStarId || conn.toStarId === activeStarId)
 109 |     .map(conn => {
 110 |       const connectedStarId = conn.fromStarId === activeStarId ? conn.toStarId : conn.fromStarId;
 111 |       const connectedStar = constellation.stars.find(s => s.id === connectedStarId);
 112 |       return { star: connectedStar, connection: conn };
 113 |     })
 114 |     .filter(item => item.star);
 115 |   
 116 |   return createPortal(
 117 |     <AnimatePresence>
 118 |       {activeStarId && activeStar && (
 119 |         <motion.div
 120 |           className="fixed inset-0 flex items-center justify-center"
 121 |           style={{ zIndex: 999999 }}
 122 |           initial={{ opacity: 0 }}
 123 |           animate={{ opacity: 1 }}
 124 |           exit={{ opacity: 0 }}
 125 |         >
 126 |           <motion.div
 127 |             className="absolute inset-0 bg-black bg-opacity-70 backdrop-blur-sm"
 128 |             initial={{ opacity: 0 }}
 129 |             animate={{ opacity: 1 }}
 130 |             exit={{ opacity: 0 }}
 131 |             onClick={handleClose}
 132 |           />
 133 |           
 134 |           <motion.div
 135 |             className="oracle-card rounded-lg w-full max-w-lg mx-4 overflow-hidden z-10"
 136 |             initial={{ opacity: 0, y: 20, scale: 0.9 }}
 137 |             animate={{ opacity: 1, y: 0, scale: 1 }}
 138 |             exit={{ opacity: 0, y: 20, scale: 0.9 }}
 139 |             transition={{ type: 'spring', damping: 25 }}
 140 |           >
 141 |             {/* 星星图像 */}
 142 |             <div className="relative">
 143 |               <img
 144 |                 src={activeStar.imageUrl}
 145 |                 alt="宇宙视觉"
 146 |                 className="w-full h-48 object-cover"
 147 |               />
 148 |               
 149 |               {/* 关闭按钮 */}
 150 |               <button 
 151 |                 className="absolute top-2 right-2 bg-black bg-opacity-50 rounded-full p-1"
 152 |                 onClick={handleClose}
 153 |               >
 154 |                 <X className="w-5 h-5 text-white" />
 155 |               </button>
 156 |               
 157 |               {/* 类别标签 */}
 158 |               <div 
 159 |                 className="absolute top-2 left-2 rounded-full px-3 py-1 text-xs font-semibold"
 160 |                 style={{ 
 161 |                   backgroundColor: `${getCategoryColor(activeStar.primary_category)}20`,
 162 |                   border: `1px solid ${getCategoryColor(activeStar.primary_category)}60`,
 163 |                   color: getCategoryColor(activeStar.primary_category)
 164 |                 }}
 165 |               >
 166 |                 {activeStar.primary_category.replace('_', ' ').toUpperCase()}
 167 |               </div>
 168 |               
 169 |               {/* 特殊星星指示器 */}
 170 |               {activeStar.isSpecial && (
 171 |                 <div className="absolute top-2 right-12 bg-cosmic-purple bg-opacity-70 rounded-full px-2 py-1 text-xs">
 172 |                   ✨ 稀有天体事件
 173 |                 </div>
 174 |               )}
 175 |             </div>
 176 |             
 177 |             <div className="p-6">
 178 |               {/* 问题 */}
 179 |               <h3 className="text-lg text-gray-300 mb-2 italic">
 180 |                 "{activeStar.question}"
 181 |               </h3>
 182 |               
 183 |               {/* 神谕回应 */}
 184 |               <p className="text-xl font-heading text-white mb-4">
 185 |                 {activeStar.answer}
 186 |               </p>
 187 |               
 188 |               {/* 标签部分 */}
 189 |               <div className="mb-4">
 190 |                 <div className="flex items-center gap-2 mb-2">
 191 |                   <Tag className="w-4 h-4 text-cosmic-accent" />
 192 |                   <span className="text-sm font-semibold text-cosmic-accent">主题</span>
 193 |                   
 194 |                   {!editingTags && (
 195 |                     <button 
 196 |                       className="ml-auto text-blue-400 hover:text-blue-300 text-sm"
 197 |                       onClick={startEditingTags}
 198 |                     >
 199 |                       编辑标签
 200 |                     </button>
 201 |                   )}
 202 |                 </div>
 203 |                 
 204 |                 {!editingTags ? (
 205 |                   <div className="flex flex-wrap gap-2">
 206 |                     {activeStar.tags.map(tag => (
 207 |                       <span
 208 |                         key={tag}
 209 |                         className="px-2 py-1 bg-cosmic-purple bg-opacity-20 border border-cosmic-purple border-opacity-30 rounded-full text-xs text-white"
 210 |                       >
 211 |                         {tag}
 212 |                       </span>
 213 |                     ))}
 214 |                   </div>
 215 |                 ) : (
 216 |                   <div>
 217 |                     <div className="flex flex-wrap gap-2 mb-3">
 218 |                       {currentTags.map(tag => (
 219 |                         <div key={tag} className="bg-blue-900 bg-opacity-40 rounded-full px-3 py-1 text-sm flex items-center">
 220 |                           <span className="text-blue-300">{tag}</span>
 221 |                           <button 
 222 |                             className="ml-2 text-gray-400 hover:text-white"
 223 |                             onClick={() => removeTag(tag)}
 224 |                           >
 225 |                             &times;
 226 |                           </button>
 227 |                         </div>
 228 |                       ))}
 229 |                       {currentTags.length === 0 && (
 230 |                         <span className="text-gray-500 text-sm italic">添加标签以创建星座</span>
 231 |                       )}
 232 |                     </div>
 233 |                     
 234 |                     <div className="flex mb-3">
 235 |                       <input
 236 |                         type="text"
 237 |                         value={newTag}
 238 |                         onChange={handleTagInputChange}
 239 |                         placeholder="添加新标签..."
 240 |                         className="flex-grow bg-gray-800 text-white px-3 py-2 rounded-l-md focus:outline-none focus:ring-1 focus:ring-blue-500"
 241 |                       />
 242 |                       <button 
 243 |                         onClick={() => addTag(newTag)}
 244 |                         className="bg-blue-700 hover:bg-blue-600 text-white px-3 py-1 rounded-r-md"
 245 |                       >
 246 |                         添加
 247 |                       </button>
 248 |                     </div>
 249 |                     
 250 |                     {tagSuggestions.length > 0 && (
 251 |                       <div className="bg-gray-800 rounded-md p-2 mb-3">
 252 |                         <p className="text-gray-400 text-xs mb-2">推荐标签：</p>
 253 |                         <div className="flex flex-wrap gap-2">
 254 |                           {tagSuggestions.map(suggestion => (
 255 |                             <button
 256 |                               key={suggestion}
 257 |                               onClick={() => addTag(suggestion)}
 258 |                               disabled={currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())}
 259 |                               className={`text-xs px-2 py-1 rounded-full ${
 260 |                                 currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())
 261 |                                   ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
 262 |                                   : 'bg-gray-700 hover:bg-gray-600 text-white'
 263 |                               }`}
 264 |                             >
 265 |                               {suggestion}
 266 |                             </button>
 267 |                           ))}
 268 |                         </div>
 269 |                       </div>
 270 |                     )}
 271 |                     
 272 |                     <div className="flex justify-end gap-2">
 273 |                       <button 
 274 |                         onClick={() => setEditingTags(false)}
 275 |                         className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-1 rounded-md"
 276 |                       >
 277 |                         取消
 278 |                       </button>
 279 |                       <button 
 280 |                         onClick={saveTagChanges}
 281 |                         className="bg-green-700 hover:bg-green-600 text-white px-3 py-1 rounded-md"
 282 |                       >
 283 |                         保存更改
 284 |                       </button>
 285 |                     </div>
 286 |                   </div>
 287 |                 )}
 288 |               </div>
 289 |               
 290 |               {/* 相连的星星 */}
 291 |               {connectedStars.length > 0 && (
 292 |                 <div className="mb-4">
 293 |                   <div className="flex items-center gap-2 mb-2">
 294 |                     <StarRayIcon size={16} />
 295 |                     <span className="text-sm font-semibold text-cosmic-accent">相连的星星</span>
 296 |                   </div>
 297 |                   <div className="space-y-2">
 298 |                     {connectedStars.slice(0, 3).map(({ star, connection }) => (
 299 |                       <div 
 300 |                         key={star!.id}
 301 |                         className="flex items-center justify-between p-2 bg-cosmic-navy bg-opacity-30 rounded-md"
 302 |                       >
 303 |                         <div className="flex-1">
 304 |                           <p className="text-sm text-white truncate">"{star!.question}"</p>
 305 |                           <p className="text-xs text-gray-400">
 306 |                             共享：{connection.sharedTags?.join('、') || '相似能量'}
 307 |                           </p>
 308 |                         </div>
 309 |                         <div className="text-xs text-cosmic-accent font-semibold">
 310 |                           {Math.round(connection.strength * 100)}%
 311 |                         </div>
 312 |                       </div>
 313 |                     ))}
 314 |                   </div>
 315 |                 </div>
 316 |               )}
 317 |               
 318 |               {/* 情感基调 */}
 319 |               <div className="mb-4">
 320 |                 <div className="flex items-center gap-2 mb-1">
 321 |                   <Heart className="w-4 h-4 text-cosmic-accent" />
 322 |                   <span className="text-sm font-semibold text-cosmic-accent">情感基调</span>
 323 |                 </div>
 324 |                 <span className="text-sm text-gray-300 capitalize">
 325 |                   {activeStar.emotional_tone && activeStar.emotional_tone.length > 0 
 326 |                     ? activeStar.emotional_tone.join('、') 
 327 |                     : '中性'}
 328 |                 </span>
 329 |               </div>
 330 |               
 331 |               {/* 日期 */}
 332 |               <p className="text-sm text-gray-400 mb-4">
 333 |                 照亮于 {activeStar.createdAt.toLocaleDateString(undefined, { 
 334 |                   year: 'numeric', 
 335 |                   month: 'long', 
 336 |                   day: 'numeric' 
 337 |                 })}
 338 |               </p>
 339 |               
 340 |               {/* 操作按钮 */}
 341 |               <div className="flex justify-between">
 342 |                 <button
 343 |                   className="cosmic-button rounded-md px-3 py-2 flex items-center"
 344 |                   onClick={handleSave}
 345 |                 >
 346 |                   <Save className="w-4 h-4 mr-2" />
 347 |                   <span>保存到星图</span>
 348 |                 </button>
 349 |                 
 350 |                 <button
 351 |                   className="cosmic-button rounded-md px-3 py-2 flex items-center"
 352 |                   onClick={handleShare}
 353 |                 >
 354 |                   <Share2 className="w-4 h-4 mr-2" />
 355 |                   <span>分享星语</span>
 356 |                 </button>
 357 |               </div>
 358 |             </div>
 359 |           </motion.div>
 360 |         </motion.div>
 361 |       )}
 362 |     </AnimatePresence>,
 363 |     document.body
 364 |   );
 365 | };
 366 | 
 367 | export default StarDetail;

```

`staroracle-app_allreact/src/components/StarLoadingAnimation.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | 
   4 | interface StarLoadingAnimationProps {
   5 |   size?: number;
   6 |   className?: string;
   7 | }
   8 | 
   9 | const StarLoadingAnimation: React.FC<StarLoadingAnimationProps> = ({ 
  10 |   size = 16,
  11 |   className = "" 
  12 | }) => {
  13 |   return (
  14 |     <div className={`inline-flex items-center justify-center ${className}`}>
  15 |       <motion.div
  16 |         className="flex items-center justify-center"
  17 |         animate={{
  18 |           rotate: [0, 360],
  19 |           scale: [1, 1.1, 1],
  20 |         }}
  21 |         transition={{
  22 |           rotate: { duration: 2, repeat: Infinity, ease: "linear" },
  23 |           scale: { duration: 1, repeat: Infinity, ease: "easeInOut" }
  24 |         }}
  25 |       >
  26 |         <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
  27 |           <circle cx="12" cy="12" r="2" fill="#ffffff" />
  28 |           {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
  29 |             const angle = (i * 45) * (Math.PI / 180);
  30 |             const startX = 12 + Math.cos(angle) * 3;
  31 |             const startY = 12 + Math.sin(angle) * 3;
  32 |             const endX = 12 + Math.cos(angle) * 8;
  33 |             const endY = 12 + Math.sin(angle) * 8;
  34 |             
  35 |             return (
  36 |               <line
  37 |                 key={i}
  38 |                 x1={startX}
  39 |                 y1={startY}
  40 |                 x2={endX}
  41 |                 y2={endY}
  42 |                 stroke="#ffffff"
  43 |                 strokeWidth="1.5"
  44 |                 strokeLinecap="round"
  45 |                 opacity={0.8}
  46 |               />
  47 |             );
  48 |           })}
  49 |         </svg>
  50 |       </motion.div>
  51 |     </div>
  52 |   );
  53 | };
  54 | 
  55 | export default StarLoadingAnimation;

```

`staroracle-app_allreact/src/components/StarRayIcon.tsx`:

```tsx
   1 | import React from 'react';
   2 | 
   3 | // StarRayIcon组件接口 - 按照demo版本设计
   4 | interface StarRayIconProps {
   5 |   size?: number;
   6 |   animated?: boolean;
   7 |   iconColor?: string;
   8 |   className?: string;
   9 |   color?: string; // 保持向后兼容
  10 |   isSpecial?: boolean; // 保持向后兼容
  11 | }
  12 | 
  13 | const StarRayIcon: React.FC<StarRayIconProps> = ({ 
  14 |   size = 20, 
  15 |   animated = false, 
  16 |   iconColor = "#ffffff",
  17 |   className = "",
  18 |   color, // 向后兼容参数
  19 |   isSpecial = false // 向后兼容参数
  20 | }) => {
  21 |   // 优先使用iconColor参数，然后是color参数，最后是默认值
  22 |   const finalColor = iconColor || color || (isSpecial ? "#FFD700" : "#ffffff");
  23 |   
  24 |   return (
  25 |     <svg
  26 |       width={size}
  27 |       height={size}
  28 |       viewBox="0 0 24 24"
  29 |       fill="none"
  30 |       xmlns="http://www.w3.org/2000/svg"
  31 |       className={`star-ray-icon ${className}`}
  32 |     >
  33 |       {/* Center circle */}
  34 |       {animated ? (
  35 |         <circle
  36 |           cx="12"
  37 |           cy="12"
  38 |           r="2"
  39 |           fill={finalColor}
  40 |           className="animate-pulse"
  41 |         />
  42 |       ) : (
  43 |         <circle cx="12" cy="12" r="2" fill={finalColor} />
  44 |       )}
  45 |       
  46 |       {/* Eight rays */}
  47 |       {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
  48 |         const angle = (i * 45) * (Math.PI / 180); // Convert to radians
  49 |         const startX = 12 + Math.cos(angle) * 3;
  50 |         const startY = 12 + Math.sin(angle) * 3;
  51 |         const endX = 12 + Math.cos(angle) * 8;
  52 |         const endY = 12 + Math.sin(angle) * 8;
  53 |         
  54 |         return animated ? (
  55 |           <line
  56 |             key={i}
  57 |             x1={startX}
  58 |             y1={startY}
  59 |             x2={endX}
  60 |             y2={endY}
  61 |             stroke={finalColor}
  62 |             strokeWidth="2"
  63 |             strokeLinecap="round"
  64 |             className="animate-ray"
  65 |             style={{
  66 |               animation: `rayExpand 0.5s ease-out ${0.1 + i * 0.05}s both`,
  67 |               transformOrigin: '12px 12px'
  68 |             }}
  69 |           />
  70 |         ) : (
  71 |           <line
  72 |             key={i}
  73 |             x1={startX}
  74 |             y1={startY}
  75 |             x2={endX}
  76 |             y2={endY}
  77 |             stroke={finalColor}
  78 |             strokeWidth="2"
  79 |             strokeLinecap="round"
  80 |           />
  81 |         );
  82 |       })}
  83 |       
  84 |       {/* CSS Animation styles - 内联样式来确保动画正常工作 */}
  85 |       <style jsx>{`
  86 |         @keyframes rayExpand {
  87 |           0% {
  88 |             stroke-dasharray: 5;
  89 |             stroke-dashoffset: 5;
  90 |           }
  91 |           100% {
  92 |             stroke-dasharray: 5;
  93 |             stroke-dashoffset: 0;
  94 |           }
  95 |         }
  96 |         .animate-ray {
  97 |           stroke-dasharray: 5;
  98 |           stroke-dashoffset: 0;
  99 |         }
 100 |       `}</style>
 101 |     </svg>
 102 |   );
 103 | };
 104 | 
 105 | export default StarRayIcon; 

```

`staroracle-app_allreact/src/components/StarryBackground.tsx`:

```tsx
   1 | import React, { useEffect, useRef, useState } from 'react';
   2 | 
   3 | interface StarryBackgroundProps {
   4 |   starCount?: number;
   5 | }
   6 | 
   7 | interface BackgroundStar {
   8 |   x: number;
   9 |   y: number;
  10 |   size: number;
  11 |   opacity: number;
  12 |   speed: number;
  13 |   twinkleSpeed: number;
  14 |   twinklePhase: number;
  15 |   pulseSize: number;
  16 |   pulseSpeed: number;
  17 | }
  18 | 
  19 | interface Nebula {
  20 |   x: number;
  21 |   y: number;
  22 |   radius: number;
  23 |   color: string;
  24 |   speed: number;
  25 |   pulsePhase: number;
  26 | }
  27 | 
  28 | const StarryBackground: React.FC<StarryBackgroundProps> = ({ starCount = 100 }) => {
  29 |   const canvasRef = useRef<HTMLCanvasElement>(null);
  30 |   const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  31 |   
  32 |   useEffect(() => {
  33 |     const canvas = canvasRef.current;
  34 |     if (!canvas) return;
  35 |     
  36 |     const ctx = canvas.getContext('2d');
  37 |     if (!ctx) return;
  38 |     
  39 |     // Set canvas dimensions
  40 |     const resizeCanvas = () => {
  41 |       canvas.width = window.innerWidth;
  42 |       canvas.height = window.innerHeight;
  43 |     };
  44 |     
  45 |     window.addEventListener('resize', resizeCanvas);
  46 |     resizeCanvas();
  47 |     
  48 |     // Create stars with enhanced properties
  49 |     const stars: BackgroundStar[] = Array.from({ length: starCount }).map(() => ({
  50 |       x: Math.random() * canvas.width,
  51 |       y: Math.random() * canvas.height,
  52 |       size: Math.random() * 2 + 0.5, // 恢复原版小星星：0.5-2.5px
  53 |       opacity: Math.random() * 0.8 + 0.2, // 恢复原版透明度：0.2-1.0
  54 |       speed: Math.random() * 0.05 + 0.01,
  55 |       twinkleSpeed: Math.random() * 0.01 + 0.003,
  56 |       twinklePhase: Math.random() * Math.PI * 2,
  57 |       pulseSize: Math.random() * 0.5 + 0.5,
  58 |       pulseSpeed: Math.random() * 0.002 + 0.001,
  59 |     }));
  60 |     
  61 |     // Create nebula clouds with pulsing effect
  62 |     const nebulae: Nebula[] = Array.from({ length: 5 }).map(() => ({
  63 |       x: Math.random() * canvas.width,
  64 |       y: Math.random() * canvas.height,
  65 |       radius: Math.random() * 200 + 100,
  66 |       color: [
  67 |         `rgba(88, 101, 242, ${Math.random() * 0.1 + 0.05})`, // 恢复原版低透明度
  68 |         `rgba(93, 71, 119, ${Math.random() * 0.1 + 0.05})`,
  69 |         `rgba(44, 83, 100, ${Math.random() * 0.1 + 0.05})`,
  70 |       ][Math.floor(Math.random() * 3)],
  71 |       speed: Math.random() * 0.02 + 0.005,
  72 |       pulsePhase: Math.random() * Math.PI * 2,
  73 |     }));
  74 |     
  75 |     // Mouse move handler for interactive effects
  76 |     const handleMouseMove = (e: MouseEvent) => {
  77 |       setMousePos({ x: e.clientX, y: e.clientY });
  78 |     };
  79 |     
  80 |     canvas.addEventListener('mousemove', handleMouseMove);
  81 |     
  82 |     // Animation loop
  83 |     let animationFrameId: number;
  84 |     
  85 |     const render = (time: number) => {
  86 |       ctx.clearRect(0, 0, canvas.width, canvas.height);
  87 |       
  88 |       // Draw nebulae with pulsing effect
  89 |       nebulae.forEach(nebula => {
  90 |         const pulseScale = Math.sin(time * 0.001 + nebula.pulsePhase) * 0.2 + 1;
  91 |         const currentRadius = nebula.radius * pulseScale;
  92 |         
  93 |         const gradient = ctx.createRadialGradient(
  94 |           nebula.x, nebula.y, 0,
  95 |           nebula.x, nebula.y, currentRadius
  96 |         );
  97 |         
  98 |         gradient.addColorStop(0, nebula.color);
  99 |         gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
 100 |         
 101 |         ctx.fillStyle = gradient;
 102 |         ctx.beginPath();
 103 |         ctx.arc(nebula.x, nebula.y, currentRadius, 0, Math.PI * 2);
 104 |         ctx.fill();
 105 |         
 106 |         // Move nebula
 107 |         nebula.x += Math.sin(time * 0.0001) * nebula.speed;
 108 |         nebula.y += Math.cos(time * 0.0001) * nebula.speed;
 109 |         
 110 |         // Wrap around edges
 111 |         if (nebula.x < -currentRadius) nebula.x = canvas.width + currentRadius;
 112 |         if (nebula.x > canvas.width + currentRadius) nebula.x = -currentRadius;
 113 |         if (nebula.y < -currentRadius) nebula.y = canvas.height + currentRadius;
 114 |         if (nebula.y > canvas.height + currentRadius) nebula.y = -currentRadius;
 115 |       });
 116 |       
 117 |       // Draw stars with enhanced effects
 118 |       stars.forEach(star => {
 119 |         // Calculate distance to mouse for interactive glow
 120 |         const dx = mousePos.x - star.x;
 121 |         const dy = mousePos.y - star.y;
 122 |         const distance = Math.sqrt(dx * dx + dy * dy);
 123 |         const mouseInfluence = Math.max(0, 1 - distance / 200);
 124 |         
 125 |         // Calculate twinkling and pulsing effects
 126 |         const twinkle = Math.sin(time * star.twinkleSpeed + star.twinklePhase) * 0.3 + 0.7;
 127 |         const pulse = Math.sin(time * star.pulseSpeed) * star.pulseSize + 1;
 128 |         
 129 |         // Combine all effects for final opacity and size
 130 |         const finalOpacity = star.opacity * twinkle * (1 + mouseInfluence * 0.5);
 131 |         const finalSize = star.size * pulse * (1 + mouseInfluence);
 132 |         
 133 |         // Draw star core
 134 |         ctx.fillStyle = `rgba(255, 255, 255, ${finalOpacity})`;
 135 |         ctx.beginPath();
 136 |         ctx.arc(star.x, star.y, finalSize, 0, Math.PI * 2);
 137 |         ctx.fill();
 138 |         
 139 |         // Draw star glow
 140 |         if (mouseInfluence > 0) {
 141 |           const gradient = ctx.createRadialGradient(
 142 |             star.x, star.y, 0,
 143 |             star.x, star.y, finalSize * 4
 144 |           );
 145 |           gradient.addColorStop(0, `rgba(255, 255, 255, ${mouseInfluence * 0.3})`);
 146 |           gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
 147 |           
 148 |           ctx.fillStyle = gradient;
 149 |           ctx.beginPath();
 150 |           ctx.arc(star.x, star.y, finalSize * 4, 0, Math.PI * 2);
 151 |           ctx.fill();
 152 |         }
 153 |         
 154 |         // Move star
 155 |         star.y += star.speed;
 156 |         
 157 |         // Wrap around bottom edge
 158 |         if (star.y > canvas.height) {
 159 |           star.y = 0;
 160 |           star.x = Math.random() * canvas.width;
 161 |         }
 162 |       });
 163 |       
 164 |       animationFrameId = requestAnimationFrame(render);
 165 |     };
 166 |     
 167 |     animationFrameId = requestAnimationFrame(render);
 168 |     
 169 |     return () => {
 170 |       window.removeEventListener('resize', resizeCanvas);
 171 |       canvas.removeEventListener('mousemove', handleMouseMove);
 172 |       cancelAnimationFrame(animationFrameId);
 173 |     };
 174 |   }, [starCount]);
 175 |   
 176 |   return (
 177 |     <canvas
 178 |       ref={canvasRef}
 179 |       className="fixed top-0 left-0 w-full h-full -z-10 pointer-events-none"
 180 |     />
 181 |   );
 182 | };
 183 | 
 184 | export default StarryBackground;

```

`staroracle-app_allreact/src/components/TemplateButton.tsx`:

```tsx
   1 | import React from 'react';
   2 | import { motion } from 'framer-motion';
   3 | import { Star } from 'lucide-react';
   4 | import { useStarStore } from '../store/useStarStore';
   5 | import StarRayIcon from './StarRayIcon';
   6 | 
   7 | interface TemplateButtonProps {
   8 |   onClick: () => void;
   9 | }
  10 | 
  11 | const TemplateButton: React.FC<TemplateButtonProps> = ({ onClick }) => {
  12 |   const { hasTemplate, templateInfo } = useStarStore();
  13 | 
  14 |   const handleClick = () => {
  15 |     onClick();
  16 |   };
  17 | 
  18 |   return (
  19 |     <motion.button
  20 |       className="template-trigger-btn"
  21 |       onClick={handleClick}
  22 |       whileHover={{ scale: 1.05 }}
  23 |       whileTap={{ scale: 0.95 }}
  24 |       initial={{ opacity: 0, x: 20 }}
  25 |       animate={{ opacity: 1, x: 0 }}
  26 |       transition={{ delay: 0.5 }}
  27 |     >
  28 |       <div className="btn-content">
  29 |         <div className="btn-icon">
  30 |           <StarRayIcon size={20} animated={false} />
  31 |           {hasTemplate && (
  32 |             <motion.div
  33 |               className="template-badge"
  34 |               initial={{ scale: 0 }}
  35 |               animate={{ scale: 1 }}
  36 |             >
  37 |               ✨
  38 |             </motion.div>
  39 |           )}
  40 |         </div>
  41 |         <div className="btn-text-container">
  42 |           <span className="btn-text">
  43 |             {hasTemplate ? '更换星座' : '选择星座'}
  44 |           </span>
  45 |           {hasTemplate && templateInfo && (
  46 |             <span className="template-name">
  47 |               {templateInfo.name}
  48 |             </span>
  49 |           )}
  50 |         </div>
  51 |       </div>
  52 |       
  53 |       {/* Floating stars animation */}
  54 |       <div className="floating-stars">
  55 |         {Array.from({ length: 4 }).map((_, i) => (
  56 |           <motion.div
  57 |             key={i}
  58 |             className="floating-star"
  59 |             animate={{
  60 |               y: [-5, -15, -5],
  61 |               opacity: [0.3, 0.8, 0.3],
  62 |               scale: [0.8, 1.2, 0.8],
  63 |             }}
  64 |             transition={{
  65 |               duration: 2.5,
  66 |               repeat: Infinity,
  67 |               delay: i * 0.4,
  68 |             }}
  69 |           >
  70 |             <Star className="w-3 h-3" />
  71 |           </motion.div>
  72 |         ))}
  73 |       </div>
  74 |     </motion.button>
  75 |   );
  76 | };
  77 | 
  78 | export default TemplateButton;

```

`staroracle-app_allreact/src/components/UserMessage.tsx`:

```tsx
   1 | import React, { useState, useRef } from 'react';
   2 | import { ChatMessage } from '../types/chat';
   3 | import MessageContextMenu from './MessageContextMenu';
   4 | 
   5 | interface UserMessageProps {
   6 |   message: ChatMessage;
   7 | }
   8 | 
   9 | const UserMessage: React.FC<UserMessageProps> = ({ message }) => {
  10 |   const [contextMenu, setContextMenu] = useState({ isVisible: false, x: 0, y: 0 });
  11 |   const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
  12 |   const messageRef = useRef<HTMLDivElement>(null);
  13 |   
  14 |   // 长按处理函数
  15 |   const handleLongPress = (event: React.TouchEvent | React.MouseEvent) => {
  16 |     event.preventDefault();
  17 |     const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
  18 |     const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
  19 |     
  20 |     setContextMenu({
  21 |       isVisible: true,
  22 |       x: clientX,
  23 |       y: clientY
  24 |     });
  25 |     
  26 |     console.log('显示用户消息上下文菜单', { x: clientX, y: clientY });
  27 |   };
  28 |   
  29 |   // 触摸开始
  30 |   const handleTouchStart = (event: React.TouchEvent) => {
  31 |     const timer = setTimeout(() => {
  32 |       handleLongPress(event);
  33 |     }, 500); // 500ms长按
  34 |     setLongPressTimer(timer);
  35 |   };
  36 |   
  37 |   // 触摸结束或取消
  38 |   const handleTouchEnd = () => {
  39 |     if (longPressTimer) {
  40 |       clearTimeout(longPressTimer);
  41 |       setLongPressTimer(null);
  42 |     }
  43 |   };
  44 |   
  45 |   // 鼠标右键点击
  46 |   const handleContextMenu = (event: React.MouseEvent) => {
  47 |     event.preventDefault();
  48 |     handleLongPress(event);
  49 |   };
  50 |   
  51 |   // 关闭上下文菜单
  52 |   const handleCloseContextMenu = () => {
  53 |     setContextMenu({ isVisible: false, x: 0, y: 0 });
  54 |   };
  55 |   
  56 |   // 复制消息
  57 |   const handleContextMenuCopy = () => {
  58 |     navigator.clipboard.writeText(message.text);
  59 |     console.log('通过上下文菜单复制用户消息');
  60 |   };
  61 |   return (
  62 |     <div className="flex justify-end mb-4">
  63 |       <div className="max-w-[80%]">
  64 |         <div className="px-4 py-2 rounded-2xl bg-gray-700 text-white stellar-body">
  65 |           <div 
  66 |             ref={messageRef}
  67 |             className="whitespace-pre-wrap break-words chat-message-content"
  68 |             onTouchStart={handleTouchStart}
  69 |             onTouchEnd={handleTouchEnd}
  70 |             onTouchCancel={handleTouchEnd}
  71 |             onContextMenu={handleContextMenu}
  72 |           >
  73 |             {message.text}
  74 |           </div>
  75 |         </div>
  76 |         <div className="text-xs text-gray-400 mt-1 text-right">
  77 |           {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
  78 |         </div>
  79 |         
  80 |         {/* 上下文菜单 */}
  81 |         <MessageContextMenu
  82 |           isVisible={contextMenu.isVisible}
  83 |           position={{ x: contextMenu.x, y: contextMenu.y }}
  84 |           messageText={message.text}
  85 |           onClose={handleCloseContextMenu}
  86 |           onCopy={handleContextMenuCopy}
  87 |         />
  88 |       </div>
  89 |     </div>
  90 |   );
  91 | };
  92 | 
  93 | export default UserMessage;

```

`staroracle-app_allreact/src/index.css`:

```css
   1 | @tailwind base;
   2 | @tailwind components;
   3 | @tailwind utilities;
   4 | 
   5 | :root {
   6 |   --font-heading: 'Cinzel', serif;
   7 |   --font-body: 'Cormorant Garamond', serif;
   8 |   /* iOS安全区域变量 */
   9 |   --safe-area-inset-top: env(safe-area-inset-top, 0px);
  10 |   --safe-area-inset-right: env(safe-area-inset-right, 0px);
  11 |   --safe-area-inset-bottom: env(safe-area-inset-bottom, 0px);
  12 |   --safe-area-inset-left: env(safe-area-inset-left, 0px);
  13 | }
  14 | 
  15 | /* 二层级字体系统 - 按照用户需求重新设计 */
  16 | 
  17 | /* 第一层级：标题和Title层级 */
  18 | /* 用于: 首页"星谕"、DrawerMenu"星谕菜单"、模态框标题等所有标题性文字 */
  19 | .stellar-title {
  20 |   font-family: var(--font-heading);
  21 |   font-size: 1.125rem; /* 18px */
  22 |   font-weight: 500;
  23 |   line-height: 1.4;
  24 | }
  25 | 
  26 | /* 第二层级：正文层级 */  
  27 | /* 用于: 菜单项文字、输入框文字、按钮文字、大部分界面文字 */
  28 | .stellar-body {
  29 |   font-family: var(--font-body);
  30 |   font-size: 0.875rem; /* 14px */
  31 |   font-weight: 400;
  32 |   line-height: 1.5;
  33 | }
  34 | 
  35 | /* 聊天消息专用样式 - 优化行间距 */
  36 | .chat-message-content {
  37 |   line-height: 1.7 !important; /* 增加行间距到1.7 */
  38 |   letter-spacing: 0.02em; /* 轻微增加字符间距 */
  39 |   /* 确保段落间距一致 */
  40 |   white-space: pre-wrap;
  41 |   word-wrap: break-word;
  42 | }
  43 | 
  44 | /* 统一段落间距 - 为段落间的空行添加适当间距 */
  45 | .chat-message-content {
  46 |   /* 使用伪元素处理连续换行的渲染 */
  47 | }
  48 | 
  49 | /* 确保段落间有一致的间距 */
  50 | .chat-message-content p {
  51 |   margin: 0 0 1em 0;
  52 | }
  53 | 
  54 | .chat-message-content p:last-child {
  55 |   margin-bottom: 0;
  56 | }
  57 | 
  58 | /* 移动端触摸优化 */
  59 | * {
  60 |   -webkit-tap-highlight-color: transparent;
  61 |   -webkit-touch-callout: none;
  62 | }
  63 | 
  64 | /* 全局禁用文本选择和长按复制，提升交互体验 */
  65 | * {
  66 |   -webkit-user-select: none;
  67 |   -moz-user-select: none;
  68 |   -ms-user-select: none;
  69 |   user-select: none;
  70 | }
  71 | 
  72 | /* 允许输入框和对话框内容可以选择 */
  73 | input, textarea, [contenteditable="true"] {
  74 |   -webkit-user-select: text !important;
  75 |   -moz-user-select: text !important;
  76 |   -ms-user-select: text !important;
  77 |   user-select: text !important;
  78 | }
  79 | 
  80 | /* 禁用聊天消息的直接文字选择 - 改为通过长按菜单复制 */
  81 | .chat-message-content {
  82 |   -webkit-user-select: none !important;
  83 |   -moz-user-select: none !important;
  84 |   -ms-user-select: none !important;
  85 |   user-select: none !important;
  86 |   /* 禁用iOS长按选择 */
  87 |   -webkit-touch-callout: none !important;
  88 |   -webkit-tap-highlight-color: transparent !important;
  89 | }
  90 | 
  91 | /* 禁用双击缩放 */
  92 | input, textarea, button, select {
  93 |   touch-action: manipulation;
  94 | }
  95 | 
  96 | /* 重置输入框默认样式 - 移除浏览器默认边框 */
  97 | input {
  98 |   border: none !important;
  99 |   outline: none !important;
 100 |   box-shadow: none !important;
 101 |   -webkit-appearance: none;
 102 |   appearance: none;
 103 | }
 104 | 
 105 | /* iOS专用输入框优化 - 确保键盘弹起 */
 106 | @supports (-webkit-touch-callout: none) {
 107 |   input[type="text"] {
 108 |     -webkit-appearance: none !important;
 109 |     appearance: none !important;
 110 |     border-radius: 0 !important;
 111 |     /* 调整为14px与正文一致，但仍防止iOS缩放 */
 112 |     font-size: 14px !important;
 113 |   }
 114 |   
 115 |   /* 确保输入框在iOS上可点击 */
 116 |   input[type="text"]:focus {
 117 |     -webkit-appearance: none !important;
 118 |     appearance: none !important;
 119 |     outline: none !important;
 120 |     border: none !important;
 121 |     box-shadow: none !important;
 122 |   }
 123 |   
 124 |   /* iOS键盘同步动画优化 */
 125 |   .keyboard-aware-container {
 126 |     will-change: transform;
 127 |     -webkit-backface-visibility: hidden;
 128 |     backface-visibility: hidden;
 129 |     -webkit-perspective: 1000px;
 130 |     perspective: 1000px;
 131 |   }
 132 | }
 133 | 
 134 | /* 全局禁用缩放和滚动 */
 135 | html {
 136 |   overflow: hidden;
 137 |   position: fixed;
 138 |   width: 100%;
 139 |   height: 100%;
 140 | }
 141 | 
 142 | body {
 143 |   overflow: hidden;
 144 |   position: fixed;
 145 |   width: 100%;
 146 |   height: 100%;
 147 |   font-family: var(--font-body);
 148 |   color: #f8f9fa;
 149 |   background-color: #000;
 150 | }
 151 | 
 152 | html, body, #root {
 153 |   height: 100%;
 154 |   width: 100%;
 155 |   margin: 0;
 156 |   padding: 0;
 157 |   overflow: hidden;
 158 | }
 159 | 
 160 | /* 移动端特有的层级修复 */
 161 | @supports (-webkit-touch-callout: none) {
 162 |   .mobile-modal-fix {
 163 |     position: fixed !important;
 164 |     z-index: 999999 !important;
 165 |     top: 0 !important;
 166 |     left: 0 !important;
 167 |     right: 0 !important;
 168 |     bottom: 0 !important;
 169 |     -webkit-transform: translateZ(0);
 170 |     transform: translateZ(0);
 171 |     -webkit-backface-visibility: hidden;
 172 |     backface-visibility: hidden;
 173 |   }
 174 |   
 175 |   .modal-hardware-acceleration {
 176 |     -webkit-transform: translate3d(0, 0, 0);
 177 |     transform: translate3d(0, 0, 0);
 178 |     -webkit-perspective: 1000px;
 179 |     perspective: 1000px;
 180 |   }
 181 | }
 182 | 
 183 | /* 最高优先级的模态框容器 */
 184 | #top-level-modals {
 185 |   position: fixed !important;
 186 |   top: 0 !important;
 187 |   left: 0 !important;
 188 |   right: 0 !important;
 189 |   bottom: 0 !important;
 190 |   z-index: 2147483647 !important;
 191 |   pointer-events: none !important;
 192 | }
 193 | 
 194 | #top-level-modals > * {
 195 |   pointer-events: auto !important;
 196 | }
 197 | 
 198 | h1, h2, h3, h4, h5, h6 {
 199 |   font-family: var(--font-heading);
 200 | }
 201 | 
 202 | .cosmic-bg {
 203 |   background: radial-gradient(ellipse at bottom, #1B2735 0%, #090A0F 100%);
 204 | }
 205 | 
 206 | .cosmic-button {
 207 |   background: transparent;
 208 |   backdrop-filter: blur(4px);
 209 |   border: none;
 210 |   transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
 211 |   min-height: 48px;
 212 |   min-width: 48px;
 213 |   -webkit-appearance: none;
 214 |   appearance: none;
 215 |   color: rgba(255, 255, 255, 0.7);
 216 | }
 217 | 
 218 | .cosmic-button:hover {
 219 |   color: rgba(255, 255, 255, 1);
 220 |   transform: translateY(-2px);
 221 | }
 222 | 
 223 | /* Star Card Styles - 核心修复区域 - 最终版本 */
 224 | .star-card-container {
 225 |   position: relative;
 226 |   width: 280px;
 227 |   height: 400px;
 228 |   margin: 16px;
 229 |   border-radius: 16px;
 230 |   box-sizing: border-box;
 231 | }
 232 | 
 233 | /* iOS Safari StarCard 特定修复 */
 234 | @supports (-webkit-touch-callout: none) {
 235 |   .star-card-container {
 236 |     -webkit-transform: translateZ(0);
 237 |     transform: translateZ(0);
 238 |     -webkit-backface-visibility: hidden;
 239 |     backface-visibility: hidden;
 240 |   }
 241 |   
 242 |   .star-card-wrapper {
 243 |     -webkit-perspective: 1000px;
 244 |     -webkit-transform: translate3d(0, 0, 0);
 245 |     transform: translate3d(0, 0, 0);
 246 |   }
 247 |   
 248 |   .star-card {
 249 |     -webkit-transform-style: preserve-3d;
 250 |     -webkit-backface-visibility: hidden;
 251 |     backface-visibility: hidden;
 252 |   }
 253 |   
 254 |   .star-card-face {
 255 |     -webkit-backface-visibility: hidden;
 256 |     -webkit-transform: translateZ(0);
 257 |     transform: translateZ(0);
 258 |   }
 259 |   
 260 |   /* iOS FlexBox 修复 - 确保星座区域正确居中 */
 261 |   .star-card-bg {
 262 |     display: -webkit-flex;
 263 |     display: flex;
 264 |     -webkit-flex-direction: column;
 265 |     flex-direction: column;
 266 |     -webkit-justify-content: space-between;
 267 |     justify-content: space-between;
 268 |   }
 269 |   
 270 |   .star-card-constellation {
 271 |     -webkit-flex: 1;
 272 |     flex: 1;
 273 |     display: -webkit-flex;
 274 |     display: flex;
 275 |     -webkit-align-items: center;
 276 |     align-items: center;
 277 |     -webkit-justify-content: center;
 278 |     justify-content: center;
 279 |   }
 280 |   
 281 |   /* iOS Canvas/SVG 居中修复 */
 282 |   .constellation-svg {
 283 |     -webkit-transform: translateZ(0);
 284 |     transform: translateZ(0);
 285 |   }
 286 |   
 287 |   .planet-canvas {
 288 |     -webkit-transform: translateZ(0);
 289 |     transform: translateZ(0);
 290 |   }
 291 |   
 292 |   /* iOS 背面内容 FlexBox 修复 */
 293 |   .star-card-content {
 294 |     display: -webkit-flex;
 295 |     display: flex;
 296 |     -webkit-flex-direction: column;
 297 |     flex-direction: column;
 298 |     -webkit-justify-content: space-between;
 299 |     justify-content: space-between;
 300 |   }
 301 |   
 302 |   .question-section, .answer-section {
 303 |     -webkit-flex: 1;
 304 |     flex: 1;
 305 |     display: -webkit-flex;
 306 |     display: flex;
 307 |     -webkit-flex-direction: column;
 308 |     flex-direction: column;
 309 |     -webkit-justify-content: center;
 310 |     justify-content: center;
 311 |     -webkit-align-items: center;
 312 |     align-items: center;
 313 |   }
 314 |   
 315 |   /* iOS 子像素渲染修复 - 防止模糊 */
 316 |   .star-card-container,
 317 |   .star-card-wrapper,
 318 |   .star-card,
 319 |   .star-card-face,
 320 |   .star-card-bg,
 321 |   .star-card-constellation,
 322 |   .star-card-content {
 323 |     -webkit-font-smoothing: antialiased;
 324 |     -moz-osx-font-smoothing: grayscale;
 325 |     will-change: transform;
 326 |   }
 327 | 
 328 |   /* iOS 对话框透明按钮强制修复 - 最高优先级，移除背景色变化 */
 329 |   button.dialog-transparent-button {
 330 |     -webkit-appearance: none !important;
 331 |     appearance: none !important;
 332 |     background: transparent !important;
 333 |     background-color: transparent !important;
 334 |     background-image: none !important;
 335 |     border: none !important;
 336 |     padding: 8px !important; /* p-2 = 8px */
 337 |     color: rgba(255, 255, 255, 0.6) !important;
 338 |     transition: color 0.3s ease !important;
 339 |   }
 340 |   
 341 |   button.dialog-transparent-button:hover {
 342 |     background: transparent !important;
 343 |     background-color: transparent !important;
 344 |     color: rgba(255, 255, 255, 1) !important;
 345 |   }
 346 |   
 347 |   button.dialog-transparent-button.recording {
 348 |     background: transparent !important;
 349 |     background-color: transparent !important;
 350 |     color: rgb(239 68 68) !important; /* red-500 */
 351 |   }
 352 |   
 353 |   button.dialog-transparent-button.recording:hover {
 354 |     background: transparent !important;
 355 |     background-color: transparent !important;
 356 |     color: rgb(220 38 38) !important; /* red-600 */
 357 |   }
 358 | }
 359 | 
 360 | .star-card-wrapper {
 361 |   position: relative;
 362 |   width: 100%;
 363 |   height: 100%;
 364 |   perspective: 1000px;
 365 |   border-radius: 16px;
 366 |   box-sizing: border-box;
 367 | }
 368 | 
 369 | .star-card {
 370 |   position: relative;
 371 |   width: 100%;
 372 |   height: 100%;
 373 |   transform-style: preserve-3d;
 374 |   cursor: pointer;
 375 |   border-radius: 16px;
 376 |   box-sizing: border-box;
 377 | }
 378 | 
 379 | .star-card-face {
 380 |   position: absolute;
 381 |   width: 100%;
 382 |   height: 100%;
 383 |   backface-visibility: hidden;
 384 |   border-radius: 16px;
 385 |   overflow: hidden;
 386 |   box-sizing: border-box;
 387 | }
 388 | 
 389 | .star-card-front {
 390 |   border: 1px solid rgba(138, 95, 189, 0.3);
 391 | }
 392 | 
 393 | .star-card-back {
 394 |   background: linear-gradient(135deg, rgba(27, 39, 53, 0.95) 0%, rgba(13, 18, 30, 0.95) 100%);
 395 |   border: 1px solid rgba(255, 255, 255, 0.2);
 396 |   transform: rotateY(180deg);
 397 | }
 398 | 
 399 | /* --- 核心修复：在这里定义布局 - 最终版本 --- */
 400 | .star-card-bg {
 401 |   position: relative;
 402 |   width: 100%;
 403 |   height: 100%;
 404 |   padding: 24px;
 405 |   display: flex;
 406 |   flex-direction: column;
 407 |   justify-content: space-between; /* 确保垂直方向两端对齐 */
 408 |   box-sizing: border-box;
 409 | }
 410 | 
 411 | .star-card-constellation {
 412 |   flex: 1; /* 占据所有可用空间，实现垂直居中 */
 413 |   display: flex;
 414 |   align-items: center;
 415 |   justify-content: center; /* 水平居中 */
 416 |   box-sizing: border-box;
 417 | }
 418 | 
 419 | .constellation-svg {
 420 |   width: 160px;
 421 |   height: 160px;
 422 |   filter: drop-shadow(0 0 10px rgba(255, 255, 255, 0.3));
 423 | }
 424 | 
 425 | .planet-canvas {
 426 |   display: block;
 427 |   margin: 0 auto;
 428 |   box-sizing: border-box;
 429 | }
 430 | /* --- 修复结束 --- */
 431 | 
 432 | .star-card-title {
 433 |   display: flex;
 434 |   flex-direction: column;
 435 |   gap: 8px;
 436 | }
 437 | 
 438 | .star-type-badge {
 439 |   display: flex;
 440 |   align-items: center;
 441 |   gap: 6px;
 442 |   padding: 6px 12px;
 443 |   background: rgba(138, 95, 189, 0.2);
 444 |   border: 1px solid rgba(138, 95, 189, 0.3);
 445 |   border-radius: 20px;
 446 |   font-size: 12px;
 447 |   color: #fff;
 448 |   width: fit-content;
 449 | }
 450 | 
 451 | .star-date {
 452 |   display: flex;
 453 |   align-items: center;
 454 |   gap: 6px;
 455 |   font-size: 11px;
 456 |   color: rgba(255, 255, 255, 0.6);
 457 | }
 458 | 
 459 | .star-card-decorations {
 460 |   position: absolute;
 461 |   inset: 0;
 462 |   pointer-events: none;
 463 | }
 464 | 
 465 | .floating-particle {
 466 |   position: absolute;
 467 |   width: 4px;
 468 |   height: 4px;
 469 |   background: rgba(255, 255, 255, 0.6);
 470 |   border-radius: 50%;
 471 |   filter: blur(0.5px);
 472 | }
 473 | 
 474 | .star-card-content {
 475 |   padding: 24px;
 476 |   height: 100%;
 477 |   display: flex;
 478 |   flex-direction: column;
 479 |   justify-content: space-between;
 480 |   text-align: center;
 481 |   box-sizing: border-box;
 482 | }
 483 | 
 484 | .question-section, .answer-section {
 485 |   flex: 1;
 486 |   display: flex;
 487 |   flex-direction: column;
 488 |   justify-content: center;
 489 | }
 490 | 
 491 | .answer-section {
 492 |   flex: 2; /* 给答案区域更多空间，因为答案通常更长 */
 493 | }
 494 | 
 495 | .question-label, .answer-label {
 496 |   font-family: var(--font-heading);
 497 |   font-size: 14px;
 498 |   color: rgba(138, 95, 189, 1);
 499 |   margin-bottom: 8px;
 500 |   text-transform: uppercase;
 501 |   letter-spacing: 1px;
 502 | }
 503 | 
 504 | .question-text {
 505 |   font-size: 16px;
 506 |   color: rgba(255, 255, 255, 0.9);
 507 |   line-height: 1.4;
 508 |   font-style: italic;
 509 |   text-align: center;
 510 | }
 511 | 
 512 | .answer-text {
 513 |   font-size: 15px;
 514 |   color: #fff;
 515 |   line-height: 1.5;
 516 |   font-family: var(--font-body);
 517 |   text-align: center;
 518 | }
 519 | 
 520 | .divider {
 521 |   display: flex;
 522 |   justify-content: center;
 523 |   align-items: center;
 524 |   margin: 16px 0;
 525 |   opacity: 0.6;
 526 | }
 527 | 
 528 | .card-footer {
 529 |   margin-top: 16px;
 530 |   padding-top: 16px;
 531 |   border-top: 1px solid rgba(255, 255, 255, 0.1);
 532 |   text-align: center;
 533 | }
 534 | 
 535 | .star-stats {
 536 |   display: flex;
 537 |   justify-content: center;
 538 |   gap: 16px;
 539 |   font-size: 11px;
 540 |   color: rgba(255, 255, 255, 0.5);
 541 | }
 542 | 
 543 | .star-card-glow {
 544 |   position: absolute;
 545 |   inset: -4px;
 546 |   background: linear-gradient(135deg, 
 547 |     rgba(138, 95, 189, 0.3) 0%, 
 548 |     rgba(88, 101, 242, 0.3) 100%
 549 |   );
 550 |   border-radius: 20px;
 551 |   filter: blur(8px);
 552 |   z-index: -1;
 553 | }
 554 | 
 555 | .star-card-actions {
 556 |   position: absolute;
 557 |   top: 12px;
 558 |   right: 12px;
 559 |   display: flex;
 560 |   gap: 8px;
 561 |   z-index: 10;
 562 | }
 563 | 
 564 | .action-btn {
 565 |   width: 32px;
 566 |   height: 32px;
 567 |   border-radius: 50%;
 568 |   background: rgba(0, 0, 0, 0.5);
 569 |   backdrop-filter: blur(4px);
 570 |   border: 1px solid rgba(255, 255, 255, 0.2);
 571 |   color: #fff;
 572 |   display: flex;
 573 |   align-items: center;
 574 |   justify-content: center;
 575 |   transition: all 0.2s ease;
 576 | }
 577 | 
 578 | .action-btn:hover {
 579 |   background: rgba(138, 95, 189, 0.3);
 580 |   transform: scale(1.1);
 581 | }
 582 | 
 583 | /* Collection Panel Styles */
 584 | .star-collection-panel {
 585 |   width: 90vw;
 586 |   max-width: 1200px;
 587 |   height: 85vh;
 588 |   background: rgba(13, 18, 30, 0.95);
 589 |   backdrop-filter: blur(20px);
 590 |   border: 1px solid rgba(255, 255, 255, 0.1);
 591 |   border-radius: 20px;
 592 |   overflow: hidden;
 593 |   display: flex;
 594 |   flex-direction: column;
 595 | }
 596 | 
 597 | .collection-header {
 598 |   display: flex;
 599 |   justify-content: space-between;
 600 |   align-items: center;
 601 |   padding: 24px 32px;
 602 |   border-bottom: 1px solid rgba(255, 255, 255, 0.1);
 603 |   background: rgba(27, 39, 53, 0.5);
 604 | }
 605 | 
 606 | .header-left {
 607 |   display: flex;
 608 |   align-items: center;
 609 |   gap: 12px;
 610 | }
 611 | 
 612 | .collection-title {
 613 |   font-family: var(--font-heading);
 614 |   font-size: 24px;
 615 |   color: #fff;
 616 |   margin: 0;
 617 | }
 618 | 
 619 | .star-count {
 620 |   padding: 4px 12px;
 621 |   background: rgba(138, 95, 189, 0.2);
 622 |   border: 1px solid rgba(138, 95, 189, 0.3);
 623 |   border-radius: 12px;
 624 |   font-size: 12px;
 625 |   color: rgba(255, 255, 255, 0.8);
 626 | }
 627 | 
 628 | .close-btn {
 629 |   width: 40px;
 630 |   height: 40px;
 631 |   border-radius: 50%;
 632 |   background: rgba(255, 255, 255, 0.1);
 633 |   border: 1px solid rgba(255, 255, 255, 0.2);
 634 |   color: #fff;
 635 |   display: flex;
 636 |   align-items: center;
 637 |   justify-content: center;
 638 |   transition: all 0.2s ease;
 639 | }
 640 | 
 641 | .close-btn:hover {
 642 |   background: rgba(255, 255, 255, 0.2);
 643 |   transform: scale(1.05);
 644 | }
 645 | 
 646 | .collection-controls {
 647 |   display: flex;
 648 |   justify-content: space-between;
 649 |   align-items: center;
 650 |   padding: 20px 32px;
 651 |   gap: 16px;
 652 |   border-bottom: 1px solid rgba(255, 255, 255, 0.05);
 653 | }
 654 | 
 655 | .search-bar {
 656 |   position: relative;
 657 |   flex: 1;
 658 |   max-width: 300px;
 659 | }
 660 | 
 661 | .search-bar svg {
 662 |   position: absolute;
 663 |   left: 12px;
 664 |   top: 50%;
 665 |   transform: translateY(-50%);
 666 | }
 667 | 
 668 | .search-input {
 669 |   width: 100%;
 670 |   padding: 10px 12px 10px 40px;
 671 |   background: rgba(255, 255, 255, 0.05);
 672 |   border: 1px solid rgba(255, 255, 255, 0.1);
 673 |   border-radius: 8px;
 674 |   color: #fff;
 675 |   font-size: 14px;
 676 | }
 677 | 
 678 | .search-input::placeholder {
 679 |   color: rgba(255, 255, 255, 0.4);
 680 | }
 681 | 
 682 | .search-input:focus {
 683 |   outline: none;
 684 |   border-color: rgba(138, 95, 189, 0.5);
 685 |   box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
 686 | }
 687 | 
 688 | .control-buttons {
 689 |   display: flex;
 690 |   align-items: center;
 691 |   gap: 12px;
 692 | }
 693 | 
 694 | .filter-select {
 695 |   padding: 8px 12px;
 696 |   background: rgba(255, 255, 255, 0.05);
 697 |   border: 1px solid rgba(255, 255, 255, 0.1);
 698 |   border-radius: 6px;
 699 |   color: #fff;
 700 |   font-size: 14px;
 701 | }
 702 | 
 703 | .filter-select:focus {
 704 |   outline: none;
 705 |   border-color: rgba(138, 95, 189, 0.5);
 706 | }
 707 | 
 708 | .collection-content {
 709 |   flex: 1;
 710 |   overflow-y: auto;
 711 |   padding: 24px 32px;
 712 | }
 713 | 
 714 | /* 核心修复：只保留grid布局，彻底移除所有list相关规则 */
 715 | .collection-content.grid {
 716 |   display: flex;
 717 |   flex-wrap: wrap;
 718 |   justify-content: center;
 719 |   gap: 24px;
 720 | }
 721 | 
 722 | .empty-state {
 723 |   display: flex;
 724 |   flex-direction: column;
 725 |   align-items: center;
 726 |   justify-content: center;
 727 |   height: 200px;
 728 |   text-align: center;
 729 | }
 730 | 
 731 | /* Collection Button Styles - 更新为透明无背景色变化风格 */
 732 | .collection-trigger-btn {
 733 |   position: relative;
 734 |   padding: 16px 24px;
 735 |   min-height: 48px;
 736 |   min-width: 48px;
 737 |   background: transparent;
 738 |   backdrop-filter: blur(10px);
 739 |   border: none;
 740 |   border-radius: 12px;
 741 |   color: rgba(255, 255, 255, 0.8);
 742 |   transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
 743 |   overflow: hidden;
 744 |   -webkit-appearance: none;
 745 |   appearance: none;
 746 | }
 747 | 
 748 | .collection-trigger-btn:hover {
 749 |   color: rgba(255, 255, 255, 1);
 750 |   transform: translateY(-2px);
 751 | }
 752 | 
 753 | .template-trigger-btn {
 754 |   position: relative;
 755 |   padding: 16px 24px;
 756 |   min-height: 48px;
 757 |   min-width: 48px;
 758 |   background: transparent;
 759 |   backdrop-filter: blur(10px);
 760 |   border: none;
 761 |   border-radius: 12px;
 762 |   color: rgba(255, 255, 255, 0.8);
 763 |   transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
 764 |   overflow: hidden;
 765 |   min-width: 160px;
 766 |   -webkit-appearance: none;
 767 |   appearance: none;
 768 | }
 769 | 
 770 | .template-trigger-btn:hover {
 771 |   color: rgba(255, 255, 255, 1);
 772 |   transform: translateY(-2px);
 773 | }
 774 | 
 775 | /* 其他必要的样式保持简洁 */
 776 | .star {
 777 |   position: absolute;
 778 |   background-color: #fff;
 779 |   border-radius: 50%;
 780 |   filter: blur(1px);
 781 |   transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
 782 | }
 783 | 
 784 | .star:hover {
 785 |   filter: blur(0);
 786 |   box-shadow: 0 0 15px rgba(255, 255, 255, 0.8),
 787 |               0 0 30px rgba(255, 255, 255, 0.6),
 788 |               0 0 45px rgba(255, 255, 255, 0.4);
 789 | }
 790 | 
 791 | .constellation-area {
 792 |   cursor: crosshair;
 793 | }
 794 | 
 795 | .constellation-area::before {
 796 |   content: '';
 797 |   position: fixed;
 798 |   width: 300px;
 799 |   height: 300px;
 800 |   border-radius: 50%;
 801 |   background: radial-gradient(circle, 
 802 |     rgba(138, 95, 189, 0.15) 0%,
 803 |     rgba(138, 95, 189, 0.1) 30%,
 804 |     transparent 70%
 805 |   );
 806 |   transform: translate(-50%, -50%);
 807 |   pointer-events: none;
 808 |   opacity: 0;
 809 |   transition: opacity 0.3s ease;
 810 |   z-index: 1;
 811 | }
 812 | 
 813 | .constellation-area:hover::before {
 814 |   opacity: 1;
 815 | }
 816 | 
 817 | @keyframes twinkle {
 818 |   0% { opacity: 0.3; transform: scale(1); }
 819 |   50% { opacity: 1; transform: scale(1.2); }
 820 |   100% { opacity: 0.3; transform: scale(1); }
 821 | }
 822 | 
 823 | @keyframes pulse {
 824 |   0% { transform: scale(1); opacity: 1; }
 825 |   50% { transform: scale(1.1); opacity: 0.8; }
 826 |   100% { transform: scale(1); opacity: 1; }
 827 | }
 828 | 
 829 | @keyframes float {
 830 |   0% { transform: translateY(0); }
 831 |   50% { transform: translateY(-10px); }
 832 |   100% { transform: translateY(0); }
 833 | }
 834 | 
 835 | .pulse {
 836 |   animation: pulse 2s infinite ease-in-out;
 837 | }
 838 | 
 839 | .twinkle {
 840 |   animation: twinkle 3s infinite ease-in-out;
 841 | }
 842 | 
 843 | .float {
 844 |   animation: float 6s infinite ease-in-out;
 845 | }
 846 | 
 847 | /*
 848 |  * 关键修复：重置 iOS/Safari 上按钮的默认原生外观。
 849 |  * 这会移除 iOS 强加的灰色背景和边框，
 850 |  * 从而让我们的 Tailwind CSS 类可以正常、无干扰地生效。
 851 |  */
 852 | button {
 853 |   -webkit-appearance: none;
 854 |   appearance: none;
 855 | }
 856 | 
 857 | /* 对话框透明按钮样式 - 解决iOS Safari bg-transparent失效问题，移除背景色变化 */
 858 | .dialog-transparent-button {
 859 |   background: transparent !important;
 860 |   background-color: transparent !important;
 861 |   background-image: none !important;
 862 |   border: none !important;
 863 |   color: rgba(255, 255, 255, 0.6) !important;
 864 |   transition: color 0.3s ease !important;
 865 |   outline: none !important;
 866 |   box-shadow: none !important;
 867 | }
 868 | 
 869 | .dialog-transparent-button:hover {
 870 |   background: transparent !important;
 871 |   background-color: transparent !important;
 872 |   color: rgba(255, 255, 255, 1) !important;
 873 | }
 874 | 
 875 | .dialog-transparent-button:focus {
 876 |   background: transparent !important;
 877 |   background-color: transparent !important;
 878 |   color: rgba(255, 255, 255, 1) !important;
 879 |   outline: none !important;
 880 |   box-shadow: none !important;
 881 | }
 882 | 
 883 | .dialog-transparent-button:active {
 884 |   background: transparent !important;
 885 |   background-color: transparent !important;
 886 |   color: rgba(255, 255, 255, 1) !important;
 887 | }
 888 | 
 889 | .dialog-transparent-button.recording {
 890 |   background: transparent !important;
 891 |   background-color: transparent !important;
 892 |   color: rgb(239 68 68) !important; /* red-500 */
 893 | }
 894 | 
 895 | .dialog-transparent-button.recording:hover {
 896 |   background: transparent !important;
 897 |   background-color: transparent !important;
 898 |   color: rgb(220 38 38) !important; /* red-600 */
 899 | }
 900 | 
 901 | .dialog-transparent-button.recording:focus {
 902 |   background: transparent !important;
 903 |   background-color: transparent !important;
 904 |   color: rgb(220 38 38) !important; /* red-600 */
 905 |   outline: none !important;
 906 |   box-shadow: none !important;
 907 | }
 908 | 
 909 | .dialog-transparent-button.recording:active {
 910 |   background: transparent !important;
 911 |   background-color: transparent !important;
 912 |   color: rgb(220 38 38) !important; /* red-600 */
 913 | }
 914 | 
 915 | /* 隐藏滚动条样式 - 保持滚动功能但隐藏视觉滚动条 */
 916 | .scrollbar-hidden {
 917 |   /* Firefox */
 918 |   scrollbar-width: none;
 919 |   /* IE and Edge */
 920 |   -ms-overflow-style: none;
 921 | }
 922 | 
 923 | .scrollbar-hidden::-webkit-scrollbar {
 924 |   /* Chrome, Safari and Opera */
 925 |   display: none;
 926 | }
 927 | 
 928 | /* 确保滚动在移动设备上仍然流畅 */
 929 | .scrollbar-hidden {
 930 |   -webkit-overflow-scrolling: touch;
 931 |   overflow: -moz-scrollbars-none;
 932 | }

```

`staroracle-app_allreact/src/main.tsx`:

```tsx
   1 | import { StrictMode } from 'react';
   2 | import { createRoot } from 'react-dom/client';
   3 | import App from './App.tsx';
   4 | import ErrorBoundary from './ErrorBoundary.tsx';
   5 | import './index.css';
   6 | 
   7 | createRoot(document.getElementById('root')!).render(
   8 |   <StrictMode>
   9 |     <ErrorBoundary>
  10 |       <App />
  11 |     </ErrorBoundary>
  12 |   </StrictMode>
  13 | );

```

`staroracle-app_allreact/src/store/useChatStore.ts`:

```ts
   1 | import { create } from 'zustand';
   2 | import { ChatMessage, ChatState, AwarenessInsight } from '../types/chat';
   3 | 
   4 | // 整体对话觉察状态
   5 | export interface ConversationAwareness {
   6 |   overallLevel: 'none' | 'low' | 'medium' | 'high';
   7 |   conversationDepth: number; // 0-100
   8 |   isAnalyzing: boolean;
   9 |   insights: AwarenessInsight[];
  10 |   topicProgression: string[]; // 话题演进
  11 | }
  12 | 
  13 | interface ChatStore extends ChatState {
  14 |   // 现有方法
  15 |   addUserMessage: (text: string) => void;
  16 |   addAIMessage: (text: string) => void;
  17 |   addStreamingAIMessage: (text: string) => string; // 返回消息ID
  18 |   updateStreamingMessage: (id: string, text: string) => void;
  19 |   finalizeStreamingMessage: (id: string) => void;
  20 |   setLoading: (loading: boolean) => void;
  21 |   clearMessages: () => void;
  22 |   
  23 |   // 对话命名功能
  24 |   conversationTitle: string;
  25 |   setConversationTitle: (title: string) => void;
  26 |   generateConversationTitle: () => Promise<void>;
  27 |   
  28 |   // 单条消息觉察分析
  29 |   startAwarenessAnalysis: (messageId: string) => void;
  30 |   completeAwarenessAnalysis: (messageId: string, insight: AwarenessInsight) => void;
  31 |   
  32 |   // 整体对话觉察状态
  33 |   conversationAwareness: ConversationAwareness;
  34 |   updateConversationAwareness: () => void;
  35 |   setConversationAnalyzing: (isAnalyzing: boolean) => void;
  36 | }
  37 | 
  38 | export const useChatStore = create<ChatStore>((set, get) => ({
  39 |   messages: [],
  40 |   isLoading: false,
  41 |   conversationTitle: '', // 初始化对话标题
  42 |   
  43 |   // 初始化对话觉察状态
  44 |   conversationAwareness: {
  45 |     overallLevel: 'none',
  46 |     conversationDepth: 0,
  47 |     isAnalyzing: false,
  48 |     insights: [],
  49 |     topicProgression: []
  50 |   },
  51 | 
  52 |   addUserMessage: (text: string) => {
  53 |     const newMessage: ChatMessage = {
  54 |       id: `user-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
  55 |       text,
  56 |       isUser: true,
  57 |       timestamp: new Date()
  58 |     };
  59 |     
  60 |     set(state => ({
  61 |       messages: [...state.messages, newMessage]
  62 |     }));
  63 |   },
  64 | 
  65 |   addAIMessage: (text: string) => {
  66 |     const newMessage: ChatMessage = {
  67 |       id: `ai-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
  68 |       text,
  69 |       isUser: false,
  70 |       timestamp: new Date()
  71 |     };
  72 |     
  73 |     set(state => ({
  74 |       messages: [...state.messages, newMessage]
  75 |     }));
  76 |   },
  77 | 
  78 |   addStreamingAIMessage: (text: string = '') => {
  79 |     const messageId = `ai-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  80 |     const newMessage: ChatMessage = {
  81 |       id: messageId,
  82 |       text,
  83 |       isUser: false,
  84 |       timestamp: new Date(),
  85 |       isStreaming: true
  86 |     };
  87 |     
  88 |     set(state => ({
  89 |       messages: [...state.messages, newMessage]
  90 |     }));
  91 |     
  92 |     return messageId;
  93 |   },
  94 | 
  95 |   updateStreamingMessage: (id: string, text: string) => {
  96 |     set(state => ({
  97 |       messages: state.messages.map(msg => 
  98 |         msg.id === id 
  99 |           ? { ...msg, text }
 100 |           : msg
 101 |       )
 102 |     }));
 103 |   },
 104 | 
 105 |   finalizeStreamingMessage: (id: string) => {
 106 |     set(state => ({
 107 |       messages: state.messages.map(msg => 
 108 |         msg.id === id 
 109 |           ? { ...msg, isStreaming: false }
 110 |           : msg
 111 |       )
 112 |     }));
 113 |   },
 114 | 
 115 |   setLoading: (loading: boolean) => {
 116 |     set({ isLoading: loading });
 117 |   },
 118 | 
 119 |   clearMessages: () => {
 120 |     set({ messages: [], isLoading: false });
 121 |   },
 122 | 
 123 |   // 开始觉察分析
 124 |   startAwarenessAnalysis: (messageId: string) => {
 125 |     set(state => ({
 126 |       messages: state.messages.map(msg => 
 127 |         msg.id === messageId 
 128 |           ? { ...msg, isAnalyzingAwareness: true }
 129 |           : msg
 130 |       )
 131 |     }));
 132 |   },
 133 | 
 134 |   // 完成觉察分析
 135 |   completeAwarenessAnalysis: (messageId: string, insight: AwarenessInsight) => {
 136 |     set(state => ({
 137 |       messages: state.messages.map(msg => 
 138 |         msg.id === messageId 
 139 |           ? { 
 140 |               ...msg, 
 141 |               isAnalyzingAwareness: false,
 142 |               awarenessInsight: insight 
 143 |             }
 144 |           : msg
 145 |       )
 146 |     }));
 147 |     
 148 |     // 完成单条分析后，更新整体对话觉察状态
 149 |     get().updateConversationAwareness();
 150 |   },
 151 | 
 152 |   // 更新整体对话觉察状态
 153 |   updateConversationAwareness: () => {
 154 |     const { messages } = get();
 155 |     
 156 |     // 收集所有有效的觉察洞察
 157 |     const allInsights = messages
 158 |       .filter(msg => !msg.isUser && msg.awarenessInsight && msg.awarenessInsight.hasInsight)
 159 |       .map(msg => msg.awarenessInsight!)
 160 |       .filter(Boolean);
 161 |     
 162 |     // 计算整体觉察等级
 163 |     let overallLevel: 'none' | 'low' | 'medium' | 'high' = 'none';
 164 |     let conversationDepth = 0;
 165 |     
 166 |     if (allInsights.length > 0) {
 167 |       // 统计不同等级的洞察数量
 168 |       const levelCounts = {
 169 |         high: allInsights.filter(i => i.insightLevel === 'high').length,
 170 |         medium: allInsights.filter(i => i.insightLevel === 'medium').length,
 171 |         low: allInsights.filter(i => i.insightLevel === 'low').length
 172 |       };
 173 |       
 174 |       // 计算对话深度 (0-100)
 175 |       conversationDepth = Math.min(100, 
 176 |         (levelCounts.high * 30 + levelCounts.medium * 20 + levelCounts.low * 10)
 177 |       );
 178 |       
 179 |       // 确定整体等级
 180 |       if (levelCounts.high >= 2 || (levelCounts.high >= 1 && levelCounts.medium >= 2)) {
 181 |         overallLevel = 'high';
 182 |       } else if (levelCounts.medium >= 2 || (levelCounts.medium >= 1 && levelCounts.low >= 3)) {
 183 |         overallLevel = 'medium';
 184 |       } else if (levelCounts.low >= 1 || levelCounts.medium >= 1) {
 185 |         overallLevel = 'low';
 186 |       }
 187 |     }
 188 |     
 189 |     // 提取话题演进
 190 |     const topicProgression = allInsights
 191 |       .map(insight => insight.insightType)
 192 |       .filter((topic, index, arr) => arr.indexOf(topic) === index); // 去重
 193 |     
 194 |     set(state => ({
 195 |       conversationAwareness: {
 196 |         ...state.conversationAwareness,
 197 |         overallLevel,
 198 |         conversationDepth,
 199 |         insights: allInsights,
 200 |         topicProgression
 201 |       }
 202 |     }));
 203 |   },
 204 | 
 205 |   // 设置对话分析状态
 206 |   setConversationAnalyzing: (isAnalyzing: boolean) => {
 207 |     set(state => ({
 208 |       conversationAwareness: {
 209 |         ...state.conversationAwareness,
 210 |         isAnalyzing
 211 |       }
 212 |     }));
 213 |   },
 214 | 
 215 |   // 对话命名功能
 216 |   setConversationTitle: (title: string) => {
 217 |     set({ conversationTitle: title });
 218 |   },
 219 | 
 220 |   generateConversationTitle: async () => {
 221 |     const { messages } = get();
 222 |     
 223 |     // 只有在有至少一轮对话且还没有标题时才生成
 224 |     if (messages.length < 2 || get().conversationTitle) return;
 225 |     
 226 |     try {
 227 |       // 导入AI工具函数
 228 |       const { generateAIResponse } = await import('../utils/aiTaggingUtils');
 229 |       
 230 |       // 取前2-3轮对话作为上下文
 231 |       const contextMessages = messages.slice(0, Math.min(6, messages.length));
 232 |       const conversation = contextMessages
 233 |         .map(msg => `${msg.isUser ? '用户' : 'AI'}：${msg.text}`)
 234 |         .join('\n');
 235 |       
 236 |       const prompt = `请为以下对话生成一个简洁的标题（不超过10个字）：
 237 | 
 238 | ${conversation}
 239 | 
 240 | 要求：
 241 | - 标题要准确反映对话的核心主题
 242 | - 使用中文
 243 | - 不超过10个字
 244 | - 不要包含标点符号
 245 | - 直接返回标题，不要其他内容`;
 246 | 
 247 |       const title = await generateAIResponse(prompt);
 248 |       
 249 |       // 清理标题：去除引号、标点等
 250 |       const cleanTitle = title
 251 |         .replace(/["'""'']/g, '') // 去除引号
 252 |         .replace(/[。！？，、；：]/g, '') // 去除中文标点
 253 |         .replace(/[.!?,;:]/g, '') // 去除英文标点
 254 |         .trim()
 255 |         .substring(0, 10); // 确保不超过10字
 256 |       
 257 |       if (cleanTitle) {
 258 |         set({ conversationTitle: cleanTitle });
 259 |         console.log('📝 已生成对话标题:', cleanTitle);
 260 |       }
 261 |     } catch (error) {
 262 |       console.error('❌ 生成对话标题失败:', error);
 263 |       // 如果生成失败，使用默认标题
 264 |       const firstUserMessage = messages.find(msg => msg.isUser)?.text || '';
 265 |       const fallbackTitle = firstUserMessage.length > 10 
 266 |         ? firstUserMessage.substring(0, 8) + '...'
 267 |         : firstUserMessage || '新对话';
 268 |       set({ conversationTitle: fallbackTitle });
 269 |     }
 270 |   }
 271 | }));

```

`staroracle-app_allreact/src/store/useStarStore.ts`:

```ts
   1 | import { create } from 'zustand';
   2 | import { Star, Connection, Constellation } from '../types';
   3 | import { generateRandomStarImage } from '../utils/imageUtils';
   4 | import { 
   5 |   analyzeStarContent, 
   6 |   generateSmartConnections,
   7 |   generateAIResponse,
   8 |   getAIConfig as getAIConfigFromUtils
   9 | } from '../utils/aiTaggingUtils';
  10 | import { instantiateTemplate } from '../utils/constellationTemplates';
  11 | import { getRandomInspirationCard, InspirationCard } from '../utils/inspirationCards';
  12 | import { ConstellationTemplate } from '../types';
  13 | 
  14 | interface StarPosition {
  15 |   x: number;
  16 |   y: number;
  17 | }
  18 | 
  19 | interface StarState {
  20 |   constellation: Constellation;
  21 |   activeStarId: string | null;
  22 |   isAsking: boolean;
  23 |   isLoading: boolean; // New state to track loading during star creation
  24 |   pendingStarPosition: StarPosition | null;
  25 |   currentInspirationCard: InspirationCard | null;
  26 |   hasTemplate: boolean;
  27 |   templateInfo: { name: string; element: string } | null;
  28 |   addStar: (question: string) => Promise<Star>;
  29 |   drawInspirationCard: () => InspirationCard;
  30 |   useInspirationCard: () => void;
  31 |   dismissInspirationCard: () => void;
  32 |   viewStar: (id: string | null) => void;
  33 |   hideStarDetail: () => void;
  34 |   setIsAsking: (isAsking: boolean, position?: StarPosition) => void;
  35 |   regenerateConnections: () => void;
  36 |   applyTemplate: (template: ConstellationTemplate) => void;
  37 |   clearConstellation: () => void;
  38 |   updateStarTags: (starId: string, newTags: string[]) => void;
  39 | }
  40 | 
  41 | // Generate initial empty constellation
  42 | const generateEmptyConstellation = (): Constellation => {
  43 |   return {
  44 |     stars: [],
  45 |     connections: []
  46 |   };
  47 | };
  48 | 
  49 | export const useStarStore = create<StarState>((set, get) => {
  50 |   // AIConfig getter - 使用集中式的配置管理
  51 |   const getAIConfig = () => {
  52 |     // 使用aiTaggingUtils中的getAIConfig来获取配置
  53 |     // 该函数会自动处理优先级：用户配置 > 系统默认配置 > 空配置
  54 |     return getAIConfigFromUtils();
  55 |   };
  56 | 
  57 |   return {
  58 |     constellation: generateEmptyConstellation(),
  59 |     activeStarId: null, // 确保初始状态为null
  60 |     isAsking: false,
  61 |     isLoading: false, // Initialize loading state as false
  62 |     pendingStarPosition: null,
  63 |     currentInspirationCard: null,
  64 |     hasTemplate: false,
  65 |     templateInfo: null,
  66 |     
  67 |     addStar: async (question: string) => {
  68 |       const { constellation, pendingStarPosition } = get();
  69 |       const { stars } = constellation;
  70 |       
  71 |       console.log(`===== User asked a question =====`);
  72 |       console.log(`Question: "${question}"`);
  73 |       
  74 |       // Set loading state to true
  75 |       set({ isLoading: true });
  76 |       
  77 |       // Get AI configuration
  78 |       const aiConfig = getAIConfig();
  79 |       console.log('Retrieved AI config result:', {
  80 |         hasApiKey: !!aiConfig.apiKey,
  81 |         hasEndpoint: !!aiConfig.endpoint,
  82 |         provider: aiConfig.provider,
  83 |         model: aiConfig.model
  84 |       });
  85 |       
  86 |       // Create new star at the clicked position or random position first (with placeholder answer)
  87 |       const x = pendingStarPosition?.x ?? (Math.random() * 70 + 15); // 15-85%
  88 |       const y = pendingStarPosition?.y ?? (Math.random() * 70 + 15); // 15-85%
  89 |       
  90 |       // Create placeholder star (we'll update it with AI response later)
  91 |       const newStar: Star = {
  92 |         id: `star-${Date.now()}`,
  93 |         x,
  94 |         y,
  95 |         size: Math.random() * 1.5 + 2.0, // Will be updated based on AI analysis
  96 |         brightness: 0.6, // Placeholder brightness
  97 |         question,
  98 |         answer: '', // Empty initially, will be filled by streaming
  99 |         imageUrl: generateRandomStarImage(),
 100 |         createdAt: new Date(),
 101 |         isSpecial: false, // Will be updated based on AI analysis
 102 |         tags: [], // Will be filled by AI analysis
 103 |         primary_category: 'philosophy_and_existence', // Placeholder
 104 |         emotional_tone: ['探寻中'], // Placeholder
 105 |         question_type: '探索型', // Placeholder
 106 |         insight_level: { value: 1, description: '星尘' }, // Placeholder
 107 |         initial_luminosity: 10, // Placeholder
 108 |         connection_potential: 3, // Placeholder
 109 |         suggested_follow_up: '', // Will be filled by AI analysis
 110 |         card_summary: question, // Placeholder
 111 |         isTemplate: false,
 112 |         isStreaming: true, // Mark as currently streaming
 113 |       };
 114 |       
 115 |       // Add placeholder star to constellation immediately for better UX
 116 |       const updatedStars = [...stars, newStar];
 117 |       set({
 118 |         constellation: {
 119 |           stars: updatedStars,
 120 |           connections: constellation.connections, // Keep existing connections for now
 121 |         },
 122 |         activeStarId: newStar.id, // Show the star being created
 123 |         isAsking: false,
 124 |         pendingStarPosition: null,
 125 |       });
 126 |       
 127 |       // Generate AI response with streaming
 128 |       console.log('Starting AI response generation with streaming...');
 129 |       let answer: string;
 130 |       let streamingAnswer = '';
 131 |       
 132 |       try {
 133 |         // Set up streaming callback
 134 |         const onStream = (chunk: string) => {
 135 |           streamingAnswer += chunk;
 136 |           
 137 |           // Update star with streaming content in real time
 138 |           set(state => ({
 139 |             constellation: {
 140 |               ...state.constellation,
 141 |               stars: state.constellation.stars.map(star => 
 142 |                 star.id === newStar.id 
 143 |                   ? { ...star, answer: streamingAnswer }
 144 |                   : star
 145 |               )
 146 |             }
 147 |           }));
 148 |         };
 149 |         
 150 |         answer = await generateAIResponse(question, aiConfig, onStream);
 151 |         console.log(`Got AI response: "${answer}"`);
 152 |         
 153 |         // Ensure we have a valid answer
 154 |         if (!answer || answer.trim().length === 0) {
 155 |           throw new Error('Empty AI response');
 156 |         }
 157 |       } catch (error) {
 158 |         console.warn('AI response failed, using fallback:', error);
 159 |         // Use fallback response generation
 160 |         answer = generateFallbackResponse(question);
 161 |         console.log(`Fallback response: "${answer}"`);
 162 |         
 163 |         // Update with fallback answer
 164 |         streamingAnswer = answer;
 165 |       }
 166 |       
 167 |       // Analyze content with AI for tags and categorization
 168 |       const analysis = await analyzeStarContent(question, answer, aiConfig);
 169 |       
 170 |       // Update star with final AI analysis results
 171 |       const finalStar: Star = {
 172 |         ...newStar,
 173 |         // 根据洞察等级调整星星大小，洞察等级越高，星星越大
 174 |         size: Math.random() * 1.5 + 2.0 + (analysis.insight_level?.value || 0) * 0.5, // 2.0-6.5px
 175 |         // 亮度也受洞察等级影响
 176 |         brightness: (analysis.initial_luminosity || 60) / 100, // 转换为0-1范围
 177 |         answer: streamingAnswer || answer, // Use final streamed answer
 178 |         isSpecial: Math.random() < 0.12 || (analysis.insight_level?.value || 0) >= 4, // 启明星和超新星自动成为特殊星
 179 |         tags: analysis.tags,
 180 |         primary_category: analysis.primary_category,
 181 |         emotional_tone: analysis.emotional_tone,
 182 |         question_type: analysis.question_type,
 183 |         insight_level: analysis.insight_level,
 184 |         initial_luminosity: analysis.initial_luminosity,
 185 |         connection_potential: analysis.connection_potential,
 186 |         suggested_follow_up: analysis.suggested_follow_up,
 187 |         card_summary: analysis.card_summary,
 188 |         isStreaming: false, // Streaming completed
 189 |       };
 190 |       
 191 |       console.log('⭐ Final star with AI analysis:', {
 192 |         question: finalStar.question,
 193 |         answer: finalStar.answer,
 194 |         answerLength: finalStar.answer.length,
 195 |         tags: finalStar.tags,
 196 |         primary_category: finalStar.primary_category,
 197 |         emotional_tone: finalStar.emotional_tone,
 198 |         insight_level: finalStar.insight_level,
 199 |         connection_potential: finalStar.connection_potential
 200 |       });
 201 |       
 202 |       // Update with final star and regenerate connections
 203 |       const finalStars = updatedStars.map(star => 
 204 |         star.id === newStar.id ? finalStar : star
 205 |       );
 206 |       const smartConnections = generateSmartConnections(finalStars);
 207 |       
 208 |       set({
 209 |         constellation: {
 210 |           stars: finalStars,
 211 |           connections: smartConnections,
 212 |         },
 213 |         isLoading: false, // Set loading state back to false
 214 |       });
 215 |       
 216 |       return finalStar;
 217 |     },
 218 | 
 219 |     drawInspirationCard: () => {
 220 |       const card = getRandomInspirationCard();
 221 |       console.log('🌟 Drawing inspiration card:', card.question);
 222 |       set({ currentInspirationCard: card });
 223 |       return card;
 224 |     },
 225 | 
 226 |     useInspirationCard: () => {
 227 |       const { currentInspirationCard } = get();
 228 |       if (currentInspirationCard) {
 229 |         console.log('✨ Using inspiration card for new star');
 230 |         // Start asking mode with the inspiration card question
 231 |         set({ 
 232 |           isAsking: true,
 233 |           currentInspirationCard: null 
 234 |         });
 235 |         
 236 |         // Pre-fill the question in the oracle input
 237 |         // This will be handled by the OracleInput component
 238 |       }
 239 |     },
 240 | 
 241 |     dismissInspirationCard: () => {
 242 |       console.log('👋 Dismissing inspiration card');
 243 |       set({ currentInspirationCard: null });
 244 |     },
 245 |     
 246 |     viewStar: (id: string | null) => {
 247 |       set({ activeStarId: id });
 248 |       console.log(`👁️ Viewing star: ${id}`);
 249 |     },
 250 |     
 251 |     hideStarDetail: () => {
 252 |       set({ activeStarId: null });
 253 |       console.log('👁️ Hiding star detail');
 254 |     },
 255 |     
 256 |     setIsAsking: (isAsking: boolean, position?: StarPosition) => {
 257 |       set({ 
 258 |         isAsking,
 259 |         pendingStarPosition: position ?? null,
 260 |       });
 261 |     },
 262 |     
 263 |     regenerateConnections: () => {
 264 |       const { constellation } = get();
 265 |       const smartConnections = generateSmartConnections(constellation.stars);
 266 |       
 267 |       console.log('Regenerating connections, found:', smartConnections.length);
 268 |       
 269 |       set({
 270 |         constellation: {
 271 |           ...constellation,
 272 |           connections: smartConnections,
 273 |         },
 274 |       });
 275 |     },
 276 | 
 277 |     applyTemplate: (template: ConstellationTemplate) => {
 278 |       console.log(`🌟 Applying template: ${template.chineseName}`);
 279 |       
 280 |       // Instantiate the template
 281 |       const { stars: templateStars, connections: templateConnections } = instantiateTemplate(template);
 282 |       
 283 |       // Get current user stars (non-template stars)
 284 |       const { constellation } = get();
 285 |       const userStars = constellation.stars.filter(star => !star.isTemplate);
 286 |       
 287 |       // Combine template stars with existing user stars
 288 |       const allStars = [...templateStars, ...userStars];
 289 |       
 290 |       // Generate connections including both template and smart connections
 291 |       const smartConnections = generateSmartConnections(allStars);
 292 |       const allConnections = [...templateConnections, ...smartConnections];
 293 |       
 294 |       set({
 295 |         constellation: {
 296 |           stars: allStars,
 297 |           connections: allConnections,
 298 |         },
 299 |         activeStarId: null, // 清除活动星星ID，避免阻止按钮点击
 300 |         hasTemplate: true,
 301 |         templateInfo: {
 302 |           name: template.chineseName,
 303 |           element: template.element
 304 |         }
 305 |       });
 306 |       
 307 |       console.log(`✨ Applied template with ${templateStars.length} stars and ${templateConnections.length} connections`);
 308 |     },
 309 | 
 310 |     clearConstellation: () => {
 311 |       set({
 312 |         constellation: generateEmptyConstellation(),
 313 |         activeStarId: null,
 314 |         hasTemplate: false,
 315 |         templateInfo: null,
 316 |       });
 317 |       console.log('🧹 Cleared constellation');
 318 |     },
 319 | 
 320 |     updateStarTags: (starId: string, newTags: string[]) => {
 321 |       set(state => {
 322 |         // Update the star with new tags
 323 |         const updatedStars = state.constellation.stars.map(star => 
 324 |           star.id === starId 
 325 |             ? { ...star, tags: newTags } 
 326 |             : star
 327 |         );
 328 |         
 329 |         // Regenerate connections with updated tags - ensure non-null values
 330 |         const newConnections = generateSmartConnections(updatedStars);
 331 |         
 332 |         return {
 333 |           constellation: {
 334 |             stars: updatedStars,
 335 |             connections: newConnections
 336 |           }
 337 |         };
 338 |       });
 339 |       
 340 |       console.log(`🏷️ Updated tags for star ${starId}`);
 341 |     }
 342 |   };
 343 | });
 344 | 
 345 | // Fallback response generator for when AI fails
 346 | const generateFallbackResponse = (question: string): string => {
 347 |   const lowerQuestion = question.toLowerCase();
 348 |   
 349 |   // Question-specific responses for better relevance
 350 |   if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
 351 |     const loveResponses = [
 352 |       "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
 353 |       "如同双星相互环绕，真正的连接需要独立与统一并存。",
 354 |       "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
 355 |       "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
 356 |       "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
 357 |     ];
 358 |     return loveResponses[Math.floor(Math.random() * loveResponses.length)];
 359 |   }
 360 |   
 361 |   if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
 362 |     const purposeResponses = [
 363 |       "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
 364 |       "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
 365 |       "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
 366 |       "你的目标写在你最深的喜悦和服务意愿的语言中。",
 367 |       "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
 368 |     ];
 369 |     return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
 370 |   }
 371 |   
 372 |   if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
 373 |     const successResponses = [
 374 |       "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
 375 |       "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
 376 |       "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
 377 |       "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
 378 |       "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
 379 |     ];
 380 |     return successResponses[Math.floor(Math.random() * successResponses.length)];
 381 |   }
 382 |   
 383 |   if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
 384 |     const fearResponses = [
 385 |       "恐惧是你潜能投下的阴影。转向光明，看它消失。",
 386 |       "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
 387 |       "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
 388 |       "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
 389 |       "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
 390 |     ];
 391 |     return fearResponses[Math.floor(Math.random() * fearResponses.length)];
 392 |   }
 393 |   
 394 |   if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
 395 |     const futureResponses = [
 396 |       "未来是你通过连接选择之星而创造的星座。",
 397 |       "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
 398 |       "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
 399 |       "未来以直觉的语言低语；用心聆听，而非恐惧。",
 400 |       "明天的轮廓隐藏在今日的每一个微小决定中。",
 401 |     ];
 402 |     return futureResponses[Math.floor(Math.random() * futureResponses.length)];
 403 |   }
 404 |   
 405 |   if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
 406 |     const happinessResponses = [
 407 |       "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
 408 |       "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
 409 |       "满足来自于将你内在的星座与外在的表达对齐。",
 410 |       "真正的快乐从内心辐射，如恒星产生自己的光和热。",
 411 |       "幸福如花朵，在感恩的土壤中最容易绽放。",
 412 |     ];
 413 |     return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
 414 |   }
 415 |   
 416 |   // General mystical responses for other questions
 417 |   const generalResponses = [
 418 |     "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
 419 |     "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
 420 |     "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
 421 |     "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
 422 |     "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
 423 |     "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
 424 |     "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
 425 |     "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
 426 |     "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
 427 |     "你的问题在宇宙中回响，带着星光承载的智慧归来。",
 428 |     "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
 429 |     "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
 430 |     "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
 431 |     "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
 432 |     "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
 433 |   ];
 434 |   
 435 |   return generalResponses[Math.floor(Math.random() * generalResponses.length)];
 436 | };

```

`staroracle-app_allreact/src/types/chat.ts`:

```ts
   1 | // 觉察分析结果接口
   2 | export interface AwarenessInsight {
   3 |   hasInsight: boolean; // 是否包含觉察价值
   4 |   insightLevel: 'low' | 'medium' | 'high'; // 觉察深度等级
   5 |   insightType: string; // 觉察类型，如"自我认知"、"情绪洞察"等
   6 |   keyInsights: string[]; // 关键洞察点
   7 |   emotionalPattern: string; // 情绪模式分析
   8 |   suggestedReflection: string; // 建议的深入思考方向
   9 |   followUpQuestions: string[]; // 后续可以继续探索的问题
  10 | }
  11 | 
  12 | export interface ChatMessage {
  13 |   id: string;
  14 |   text: string;
  15 |   isUser: boolean;
  16 |   timestamp: Date;
  17 |   isLoading?: boolean;
  18 |   isStreaming?: boolean; // 标记是否正在流式输出
  19 |   // 觉察相关字段
  20 |   awarenessInsight?: AwarenessInsight; // AI分析的觉察洞见
  21 |   isAnalyzingAwareness?: boolean; // 是否正在分析觉察
  22 | }
  23 | 
  24 | export interface ChatState {
  25 |   messages: ChatMessage[];
  26 |   isLoading: boolean;
  27 | }

```

`staroracle-app_allreact/src/types/index.ts`:

```ts
   1 | export interface Star {
   2 |   id: string;
   3 |   x: number;
   4 |   y: number;
   5 |   size: number;
   6 |   brightness: number;
   7 |   question: string;
   8 |   answer: string;
   9 |   imageUrl: string;
  10 |   createdAt: Date;
  11 |   isSpecial: boolean;
  12 |   tags: string[];
  13 |   primary_category: string; // 更新为 primary_category
  14 |   emotional_tone: string[]; // 更新为数组类型
  15 |   question_type?: string; // 新增：问题类型
  16 |   insight_level?: {
  17 |     value: number; // 1-5
  18 |     description: string; // '星尘', '微光', '寻常星', '启明星', '超新星'
  19 |   };
  20 |   initial_luminosity?: number; // 0-100
  21 |   connection_potential?: number; // 1-5
  22 |   suggested_follow_up?: string; // 建议的追问
  23 |   card_summary?: string; // 卡片摘要
  24 |   similarity?: number; // For connection strength
  25 |   isTemplate?: boolean; // 标记是否为模板星星
  26 |   templateType?: string; // 模板类型（星座名称）
  27 |   isStreaming?: boolean; // 标记是否正在流式输出回答
  28 | }
  29 | 
  30 | export interface Connection {
  31 |   id: string;
  32 |   fromStarId: string;
  33 |   toStarId: string;
  34 |   strength: number; // 0-1, based on tag similarity
  35 |   sharedTags: string[];
  36 |   isTemplate?: boolean; // 标记是否为模板连接
  37 |   constellationName?: string; // 标记该连接所属的星座名称
  38 | }
  39 | 
  40 | export interface Constellation {
  41 |   stars: Star[];
  42 |   connections: Connection[];
  43 | }
  44 | 
  45 | // 更新为更完整的分析结构
  46 | export interface TagAnalysis {
  47 |   tags: string[];
  48 |   primary_category: string;
  49 |   emotional_tone: string[];
  50 |   question_type: string;
  51 |   insight_level: {
  52 |     value: number;
  53 |     description: string;
  54 |   };
  55 |   initial_luminosity: number;
  56 |   connection_potential: number;
  57 |   suggested_follow_up: string;
  58 |   card_summary: string;
  59 | }
  60 | 
  61 | // 星座模板接口
  62 | export interface ConstellationTemplate {
  63 |   id: string;
  64 |   name: string;
  65 |   chineseName: string;
  66 |   description: string;
  67 |   element: 'fire' | 'earth' | 'air' | 'water';
  68 |   stars: TemplateStarData[];
  69 |   connections: TemplateConnectionData[];
  70 |   centerX: number;
  71 |   centerY: number;
  72 |   scale: number;
  73 | }
  74 | 
  75 | export interface TemplateStarData {
  76 |   id: string;
  77 |   x: number; // 相对于星座中心的位置
  78 |   y: number;
  79 |   size: number;
  80 |   brightness: number;
  81 |   question: string;
  82 |   answer: string;
  83 |   tags: string[];
  84 |   category?: string; // 兼容旧的模板数据
  85 |   emotionalTone?: string; // 兼容旧的模板数据
  86 |   primary_category?: string; // 新的类别字段
  87 |   emotional_tone?: string[]; // 新的情感基调字段
  88 |   question_type?: string;
  89 |   insight_level?: {
  90 |     value: number;
  91 |     description: string;
  92 |   };
  93 |   initial_luminosity?: number;
  94 |   connection_potential?: number;
  95 |   suggested_follow_up?: string;
  96 |   card_summary?: string;
  97 |   isMainStar?: boolean; // 是否为主星
  98 | }
  99 | 
 100 | export interface TemplateConnectionData {
 101 |   fromStarId: string;
 102 |   toStarId: string;
 103 |   strength: number;
 104 |   sharedTags: string[];
 105 | }

```

`staroracle-app_allreact/src/utils/aiTaggingUtils.ts`:

```ts
   1 | // AI Tagging and Analysis Utilities
   2 | import { Star, Connection, TagAnalysis } from '../types';
   3 | import { AwarenessInsight } from '../types/chat'; // 新增导入
   4 | import type { ApiProvider } from '../vite-env';
   5 | 
   6 | export interface AITaggingConfig {
   7 |   provider?: ApiProvider; // 新增：API提供商
   8 |   apiKey?: string;
   9 |   endpoint?: string;
  10 |   model?: string;
  11 |   _version?: string; // 添加版本号用于未来可能的迁移
  12 |   _lastUpdated?: string; // 添加最后更新时间
  13 | }
  14 | 
  15 | export interface APIValidationResult {
  16 |   isValid: boolean;
  17 |   error?: string;
  18 |   responseTime?: number;
  19 |   modelInfo?: string;
  20 | }
  21 | 
  22 | // API验证函数
  23 | export const validateAIConfig = async (config: AITaggingConfig): Promise<APIValidationResult> => {
  24 |   if (!config.provider || !config.apiKey || !config.endpoint || !config.model) {
  25 |     return {
  26 |       isValid: false,
  27 |       error: '请选择提供商并填写完整的API配置信息（API Key、Endpoint、Model）'
  28 |     };
  29 |   }
  30 | 
  31 |   const startTime = Date.now();
  32 |   const testPrompt = '请简单回复"测试成功"';
  33 |   let requestBody;
  34 |   let requestHeaders = {
  35 |     'Content-Type': 'application/json',
  36 |     'Authorization': `Bearer ${config.apiKey?.replace(/[^\x20-\x7E]/g, '') || ''}`,
  37 |   };
  38 |   
  39 |   try {
  40 |     console.log(`🔍 Validating ${config.provider} API configuration...`);
  41 | 
  42 |     // 根据provider构建不同的请求体
  43 |     switch (config.provider) {
  44 |       case 'gemini':
  45 |         requestBody = {
  46 |           contents: [{ parts: [{ text: testPrompt }] }]
  47 |         };
  48 |         break;
  49 |       
  50 |       case 'openai':
  51 |       default: // OpenAI 和 NewAPI 等兼容服务
  52 |         requestBody = {
  53 |           model: config.model,
  54 |           messages: [{ role: 'user', content: testPrompt }],
  55 |           max_tokens: 10,
  56 |           temperature: 0.1,
  57 |         };
  58 |         break;
  59 |     }
  60 | 
  61 |     const response = await fetch(config.endpoint, {
  62 |       method: 'POST',
  63 |       headers: requestHeaders,
  64 |       body: JSON.stringify(requestBody),
  65 |     });
  66 | 
  67 |     const responseTime = Date.now() - startTime;
  68 | 
  69 |     if (!response.ok) {
  70 |       let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
  71 |       
  72 |       try {
  73 |         // Check if response is JSON before parsing
  74 |         const contentType = response.headers.get('content-type');
  75 |         if (contentType && contentType.includes('application/json')) {
  76 |           const errorData = await response.json();
  77 |           if (errorData.error?.message) {
  78 |             errorMessage = errorData.error.message;
  79 |           } else if (errorData.message) {
  80 |             errorMessage = errorData.message;
  81 |           }
  82 |         } else {
  83 |           // If not JSON, get text content for better error reporting
  84 |           const textContent = await response.text();
  85 |           if (textContent.includes('<!doctype') || textContent.includes('<html')) {
  86 |             errorMessage = `服务器返回了HTML页面而不是API响应。请检查endpoint地址是否正确。`;
  87 |           } else {
  88 |             errorMessage = `非JSON响应: ${textContent.slice(0, 100)}...`;
  89 |           }
  90 |         }
  91 |       } catch (parseError) {
  92 |         // If we can't parse the error response, use the HTTP status
  93 |         errorMessage = `HTTP ${response.status}: 无法解析错误响应`;
  94 |       }
  95 | 
  96 |       return {
  97 |         isValid: false,
  98 |         error: errorMessage,
  99 |         responseTime
 100 |       };
 101 |     }
 102 | 
 103 |     let data;
 104 |     try {
 105 |       // Check if response is JSON before parsing
 106 |       const contentType = response.headers.get('content-type');
 107 |       if (!contentType || !contentType.includes('application/json')) {
 108 |         const textContent = await response.text();
 109 |         return {
 110 |           isValid: false,
 111 |           error: `API返回了非JSON响应。请检查endpoint是否正确。响应内容: ${textContent.slice(0, 100)}...`,
 112 |           responseTime
 113 |         };
 114 |       }
 115 |       
 116 |       data = await response.json();
 117 |     } catch (parseError) {
 118 |       return {
 119 |         isValid: false,
 120 |         error: 'API响应不是有效的JSON格式，请检查endpoint是否支持OpenAI格式',
 121 |         responseTime
 122 |       };
 123 |     }
 124 |     
 125 |     // 根据provider解析不同的响应
 126 |     let testResponse: string | undefined;
 127 | 
 128 |     switch (config.provider) {
 129 |       case 'gemini':
 130 |         testResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
 131 |         if (!testResponse) {
 132 |           return { isValid: false, error: 'Gemini响应格式不正确', responseTime };
 133 |         }
 134 |         break;
 135 |       case 'openai':
 136 |       default:
 137 |         // 检查响应格式
 138 |         if (!data.choices || !data.choices[0] || !data.choices[0].message) {
 139 |           return {
 140 |             isValid: false,
 141 |             error: 'API响应格式不正确，请检查endpoint是否支持OpenAI格式',
 142 |             responseTime
 143 |           };
 144 |         }
 145 | 
 146 |         testResponse = data.choices[0].message.content;
 147 |         break;
 148 |     }
 149 |     
 150 |     console.log('✅ API validation successful:', {
 151 |       responseTime: `${responseTime}ms`,
 152 |       model: config.model,
 153 |       testResponse: testResponse?.slice(0, 50)
 154 |     });
 155 | 
 156 |     return {
 157 |       isValid: true,
 158 |       responseTime,
 159 |       modelInfo: `${config.model} (${responseTime}ms)`
 160 |     };
 161 | 
 162 |   } catch (error) {
 163 |     const responseTime = Date.now() - startTime;
 164 |     console.error('❌ API validation failed:', error);
 165 |     
 166 |     let errorMessage = '网络连接失败';
 167 |     if (error instanceof Error) {
 168 |       if (error.message.includes('fetch')) {
 169 |         errorMessage = '无法连接到API服务器，请检查网络和endpoint地址';
 170 |       } else if (error.message.includes('CORS')) {
 171 |         errorMessage = 'CORS错误，请检查API服务器是否允许跨域请求';
 172 |       } else if (error.message.includes('JSON')) {
 173 |         errorMessage = '服务器响应格式错误，请检查endpoint地址是否正确';
 174 |       } else {
 175 |         errorMessage = error.message;
 176 |       }
 177 |     }
 178 | 
 179 |     return {
 180 |       isValid: false,
 181 |       error: errorMessage,
 182 |       responseTime
 183 |     };
 184 |   }
 185 | };
 186 | 
 187 | // Enhanced mock AI analysis with better tag generation
 188 | const mockAIAnalysis = (question: string, answer: string): TagAnalysis => {
 189 |   const content = `${question} ${answer}`.toLowerCase();
 190 |   
 191 |   // More comprehensive tag mapping
 192 |   const tagMap = {
 193 |     // 核心生活领域 - Core Life Areas
 194 |     'love': ['relationships', 'romance', 'connection', 'heart', 'soulmate'],
 195 |     'family': ['relationships', 'parents', 'children', 'home', 'roots', 'legacy'],
 196 |     'friendship': ['connection', 'social', 'trust', 'loyalty', 'support'],
 197 |     'career': ['work', 'profession', 'vocation', 'success', 'achievement'],
 198 |     'education': ['learning', 'knowledge', 'growth', 'skills', 'wisdom'],
 199 |     'health': ['wellness', 'fitness', 'balance', 'vitality', 'self-care'],
 200 |     'finance': ['money', 'wealth', 'abundance', 'security', 'resources'],
 201 |     'spirituality': ['faith', 'soul', 'meaning', 'divinity', 'practice'],
 202 |     
 203 |     // 内在体验 - Inner Experience
 204 |     'emotions': ['feelings', 'awareness', 'processing', 'expression', 'regulation'],
 205 |     'happiness': ['joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
 206 |     'anxiety': ['fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
 207 |     'grief': ['loss', 'sadness', 'mourning', 'acceptance', 'healing'],
 208 |     'anger': ['frustration', 'resentment', 'boundaries', 'assertiveness', 'release'],
 209 |     'shame': ['guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
 210 |     
 211 |     // 自我发展 - Self Development
 212 |     'identity': ['self', 'authenticity', 'values', 'discovery', 'integration'],
 213 |     'purpose': ['meaning', 'calling', 'mission', 'direction', 'contribution'],
 214 |     'growth': ['development', 'evolution', 'improvement', 'transformation', 'potential'],
 215 |     'resilience': ['strength', 'adaptation', 'recovery', 'endurance', 'perseverance'],
 216 |     'creativity': ['expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
 217 |     'wisdom': ['insight', 'perspective', 'understanding', 'discernment', 'reflection'],
 218 |     
 219 |     // 人际关系 - Relationships
 220 |     'communication': ['expression', 'listening', 'understanding', 'clarity', 'connection'],
 221 |     'intimacy': ['closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
 222 |     'boundaries': ['limits', 'protection', 'respect', 'space', 'autonomy'],
 223 |     'conflict': ['resolution', 'understanding', 'healing', 'growth', 'peace'],
 224 |     'trust': ['faith', 'reliability', 'consistency', 'safety', 'honesty'],
 225 |     
 226 |     // 生活哲学 - Life Philosophy
 227 |     'meaning': ['purpose', 'significance', 'values', 'understanding', 'exploration'],
 228 |     'mindfulness': ['presence', 'awareness', 'attention', 'consciousness', 'being'],
 229 |     'gratitude': ['appreciation', 'thankfulness', 'recognition', 'abundance', 'positivity'],
 230 |     'legacy': ['impact', 'contribution', 'remembrance', 'influence', 'heritage'],
 231 |     'values': ['principles', 'ethics', 'morality', 'beliefs', 'priorities'],
 232 |     
 233 |     // 生活转变 - Life Transitions
 234 |     'change': ['transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
 235 |     'decision': ['choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
 236 |     'future': ['planning', 'vision', 'direction', 'goals', 'possibilities'],
 237 |     'past': ['history', 'memories', 'reflection', 'lessons', 'integration'],
 238 |     'letting-go': ['release', 'surrender', 'acceptance', 'closure', 'freedom'],
 239 |     
 240 |     // 世界关系 - Relation to World
 241 |     'nature': ['environment', 'connection', 'outdoors', 'harmony', 'elements'],
 242 |     'society': ['community', 'culture', 'belonging', 'contribution', 'citizenship'],
 243 |     'justice': ['fairness', 'equality', 'rights', 'advocacy', 'ethics'],
 244 |     'service': ['contribution', 'helping', 'impact', 'giving', 'purpose'],
 245 |     'technology': ['digital', 'tools', 'innovation', 'adaptation', 'balance']
 246 |   };
 247 |   
 248 |   // 新的类别映射到旧的类别
 249 |   const categoryMapping = {
 250 |     'relationships': 'relationships',
 251 |     'personal_growth': 'personal_growth',
 252 |     'career_and_purpose': 'career_and_purpose',
 253 |     'emotional_wellbeing': 'emotional_wellbeing',
 254 |     'philosophy_and_existence': 'philosophy_and_existence',
 255 |     'creativity_and_passion': 'creativity_and_passion',
 256 |     'daily_life': 'daily_life'
 257 |   };
 258 |   
 259 |   // 类别关键词
 260 |   const categories = {
 261 |     'relationships': ['love', 'family', 'friendship', 'connection', 'intimacy', 'communication', 'boundaries', 'trust'],
 262 |     'personal_growth': ['identity', 'purpose', 'wisdom', 'growth', 'resilience', 'spirituality', 'creativity', 'education'],
 263 |     'career_and_purpose': ['future', 'career', 'decision', 'change', 'goals', 'values', 'legacy', 'mission', 'purpose'],
 264 |     'emotional_wellbeing': ['happiness', 'health', 'emotions', 'mindfulness', 'balance', 'self-care', 'vitality', 'healing'],
 265 |     'philosophy_and_existence': ['meaning', 'purpose', 'spirituality', 'values', 'wisdom', 'legacy', 'faith', 'life', 'death'],
 266 |     'creativity_and_passion': ['creativity', 'expression', 'imagination', 'innovation', 'artistry', 'inspiration', 'passion'],
 267 |     'daily_life': ['finance', 'security', 'abundance', 'resources', 'stability', 'wealth', 'work', 'routine', 'daily', 'practical']
 268 |   };
 269 |   
 270 |   // 情感基调映射
 271 |   const emotionalToneMapping = {
 272 |     'positive': '充满希望的',
 273 |     'contemplative': '思考的',
 274 |     'seeking': '探寻中',
 275 |     'neutral': '中性的'
 276 |   };
 277 |   
 278 |   // Improved emotional tone detection
 279 |   const emotionalTones = {
 280 |     '充满希望的': ['happy', 'joy', 'gratitude', 'hope', 'excitement', 'love', 'strength', 'peace', 'confidence'],
 281 |     '思考的': ['meaning', 'purpose', 'wisdom', 'reflect', 'wonder', 'ponder', 'consider', 'understand', 'explore'],
 282 |     '探寻中': ['find', 'search', 'discover', 'seek', 'direction', 'path', 'guidance', 'answers', 'clarity', 'help'],
 283 |     '中性的': ['what', 'is', 'are', 'should', 'would', 'could', 'might', 'perhaps', 'maybe', 'possibly'],
 284 |     '焦虑的': ['anxiety', 'worry', 'stress', 'fear', 'nervous', 'uncertain', 'overwhelm'],
 285 |     '感激的': ['grateful', 'thankful', 'appreciate', 'blessing', 'gift', 'fortune'],
 286 |     '困惑的': ['confused', 'puzzled', 'unclear', 'unsure', 'complexity', 'complicated'],
 287 |     '忧郁的': ['sad', 'depressed', 'melancholy', 'down', 'blue', 'grief', 'loss'],
 288 |     '坚定的': ['determined', 'resolved', 'committed', 'decided', 'sure', 'certain', 'confident']
 289 |   };
 290 | 
 291 |   // 问题类型检测
 292 |   const questionTypePatterns = {
 293 |     '探索型': ['why', 'why do i', 'what if', 'how come', '为什么', '怎么会', '如果', '假设', '是不是因为', '可能是'],
 294 |     '实用型': ['how to', 'how can i', 'what is the way to', 'steps to', 'method', '如何', '怎么做', '方法', '步骤', '技巧'],
 295 |     '事实型': ['what is', 'when', 'where', 'who', '什么是', '何时', '何地', '谁', '哪里', '多少'],
 296 |     '表达型': ['i feel', 'i am', 'i think', 'i believe', '我觉得', '我认为', '我感到', '我相信', '我想']
 297 |   };
 298 |   
 299 |   // Extract tags based on content with better matching
 300 |   const extractedTags: string[] = [];
 301 |   let detectedCategory = 'philosophy_and_existence';
 302 |   const detectedTones: string[] = ['探寻中'];
 303 |   let questionType = '探索型';
 304 |   
 305 |   // Find matching tags with partial matching
 306 |   Object.entries(tagMap).forEach(([key, relatedTags]) => {
 307 |     if (content.includes(key) || relatedTags.some(tag => content.includes(tag))) {
 308 |       extractedTags.push(key);
 309 |       // Add 1-2 related tags for better connections but avoid too many tags
 310 |       extractedTags.push(...relatedTags.slice(0, 2));
 311 |     }
 312 |   });
 313 |   
 314 |   // Add common universal tags to ensure connections
 315 |   const universalTags = ['wisdom', 'growth', 'reflection', 'insight'];
 316 |   extractedTags.push(...universalTags.slice(0, 2));
 317 |   
 318 |   // Determine category with better matching
 319 |   Object.entries(categories).forEach(([category, keywords]) => {
 320 |     const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
 321 |     if (matchCount > 0) {
 322 |       detectedCategory = category;
 323 |     }
 324 |   });
 325 |   
 326 |   // Determine emotional tones (multiple can be detected)
 327 |   Object.entries(emotionalTones).forEach(([tone, keywords]) => {
 328 |     const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
 329 |     if (matchCount > 0 && !detectedTones.includes(tone)) {
 330 |       detectedTones.push(tone);
 331 |     }
 332 |   });
 333 |   
 334 |   // Limit to two emotional tones
 335 |   if (detectedTones.length > 2) {
 336 |     detectedTones.splice(2);
 337 |   }
 338 |   
 339 |   // Determine question type
 340 |   Object.entries(questionTypePatterns).forEach(([type, patterns]) => {
 341 |     if (patterns.some(pattern => question.toLowerCase().includes(pattern))) {
 342 |       questionType = type;
 343 |       return;
 344 |     }
 345 |   });
 346 |   
 347 |   // Ensure we have enough tags for connections
 348 |   if (extractedTags.length < 3) {
 349 |     extractedTags.push('reflection', 'insight', 'awareness');
 350 |   }
 351 |   
 352 |   // Remove duplicates and limit to 6 tags for better connections
 353 |   const uniqueTags = [...new Set(extractedTags)].slice(0, 6);
 354 |   
 355 |   // Determine insight level based on content depth
 356 |   let insightLevel = {
 357 |     value: 1,
 358 |     description: '星尘'
 359 |   };
 360 |   
 361 |   // 简单的洞察度评估规则
 362 |   if (question.length > 50 && answer.length > 150) {
 363 |     insightLevel.value = 4;
 364 |     insightLevel.description = '启明星';
 365 |   } else if (question.length > 30 && answer.length > 100) {
 366 |     insightLevel.value = 3;
 367 |     insightLevel.description = '寻常星';
 368 |   } else if (question.length > 10 && answer.length > 50) {
 369 |     insightLevel.value = 2;
 370 |     insightLevel.description = '微光';
 371 |   }
 372 |   
 373 |   // 判断是否是深度自我探索的问题
 374 |   const selfReflectionWords = ['我自己', '我的内心', '自我', '成长', '人生', '意义', '价值', '恐惧', '梦想', '目标', '自我意识'];
 375 |   if (selfReflectionWords.some(word => content.includes(word))) {
 376 |     insightLevel.value = Math.min(5, insightLevel.value + 1);
 377 |     if (insightLevel.value >= 4) {
 378 |       insightLevel.description = insightLevel.value === 5 ? '超新星' : '启明星';
 379 |     }
 380 |   }
 381 |   
 382 |   // 计算初始亮度
 383 |   const luminosityMap = [0, 10, 30, 60, 90, 100];
 384 |   const initialLuminosity = luminosityMap[insightLevel.value];
 385 |   
 386 |   // 确定连接潜力
 387 |   let connectionPotential = 3; // 默认中等连接潜力
 388 |   
 389 |   // 通用主题有较高的连接潜力
 390 |   const universalThemes = ['love', 'purpose', 'meaning', 'growth', 'change', 'fear', 'happiness', 'success'];
 391 |   if (universalThemes.some(theme => uniqueTags.includes(theme))) {
 392 |     connectionPotential = 5;
 393 |   } else if (uniqueTags.length <= 2) {
 394 |     connectionPotential = 1; // 标签很少，连接潜力低
 395 |   } else if (uniqueTags.length >= 5) {
 396 |     connectionPotential = 4; // 标签多，连接潜力高
 397 |   }
 398 |   
 399 |   // 生成简单的卡片摘要
 400 |   let cardSummary = question.length > 30 ? question : question + " - " + answer.slice(0, 40) + "...";
 401 |   
 402 |   // 生成追问
 403 |   let suggestedFollowUp = '';
 404 |   const followUpMap: Record<string, string> = {
 405 |     'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
 406 |     'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
 407 |     'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
 408 |     'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
 409 |     'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
 410 |     'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
 411 |     'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
 412 |   };
 413 |   
 414 |   suggestedFollowUp = followUpMap[detectedCategory] || '关于这个话题，你还有什么更深层次的感受或想法？';
 415 |   
 416 |   return {
 417 |     tags: uniqueTags,
 418 |     primary_category: detectedCategory,
 419 |     emotional_tone: detectedTones,
 420 |     question_type: questionType,
 421 |     insight_level: insightLevel,
 422 |     initial_luminosity: initialLuminosity,
 423 |     connection_potential: connectionPotential,
 424 |     suggested_follow_up: suggestedFollowUp,
 425 |     card_summary: cardSummary
 426 |   };
 427 | };
 428 | 
 429 | // Main AI tagging function
 430 | export const analyzeStarContent = async (
 431 |   question: string, 
 432 |   answer: string,
 433 |   config?: AITaggingConfig,
 434 |   userHistory?: { previousInsightLevel: number, recentTags: string[] }
 435 | ): Promise<TagAnalysis> => {
 436 |   try {
 437 |     // Always try to use AI service first
 438 |     if (config?.apiKey && config?.endpoint) {
 439 |       console.log(`🤖 使用${config.provider || 'openai'}服务进行内容分析`);
 440 |       console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
 441 |       return await callAIService(question, answer, config);
 442 |     } else {
 443 |       // Try to use default API config if available
 444 |       const defaultConfig = getAIConfig();
 445 |       if (defaultConfig.apiKey && defaultConfig.endpoint) {
 446 |         console.log(`🤖 使用默认${defaultConfig.provider || 'openai'}配置进行内容分析`);
 447 |         console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
 448 |         return await callAIService(question, answer, defaultConfig);
 449 |       }
 450 |     }
 451 |     
 452 |     console.warn('⚠️ 未找到AI配置，使用模拟内容分析');
 453 |     // Fallback to mock analysis if no API config is available
 454 |     return mockAIAnalysis(question, answer);
 455 |   } catch (error) {
 456 |     console.warn('❌ AI标签生成失败，使用备用方案:', error);
 457 |     return mockAIAnalysis(question, answer);
 458 |   }
 459 | };
 460 | 
 461 | // Generate AI response for oracle answers with optional streaming
 462 | export const generateAIResponse = async (
 463 |   question: string,
 464 |   config?: AITaggingConfig,
 465 |   onStream?: (chunk: string) => void,
 466 |   conversationHistory?: Array<{role: 'user' | 'assistant', content: string}>
 467 | ): Promise<string> => {
 468 |   console.log('===== Starting AI answer generation =====');
 469 |   console.log('Question:', question);
 470 |   console.log('Passed config:', config ? 'Has config' : 'No config');
 471 |   console.log('Streaming enabled:', !!onStream);
 472 |   console.log('Conversation history length:', conversationHistory ? conversationHistory.length : 0);
 473 |   console.log('onStream type:', typeof onStream);
 474 |   
 475 |   try {
 476 |     if (config?.apiKey && config?.endpoint) {
 477 |       console.log(`Using passed ${config.provider || 'openai'} service to generate answer`);
 478 |       console.log('Config details:', {
 479 |         provider: config.provider,
 480 |         endpoint: config.endpoint,
 481 |         model: config.model,
 482 |         hasApiKey: !!config.apiKey
 483 |       });
 484 |       console.log('🔍 About to call callAIForResponse with onStream:', !!onStream);
 485 |       const aiResponse = await callAIForResponse(question, config, onStream, conversationHistory);
 486 |       console.log('AI generated answer:', aiResponse);
 487 |       return aiResponse;
 488 |     }
 489 |     
 490 |     // Try using default config
 491 |     const defaultConfig = getAIConfig();
 492 |     console.log('Retrieved default config:', {
 493 |       hasApiKey: !!defaultConfig.apiKey,
 494 |       hasEndpoint: !!defaultConfig.endpoint,
 495 |       provider: defaultConfig.provider,
 496 |       model: defaultConfig.model,
 497 |       endpoint: defaultConfig.endpoint
 498 |     });
 499 |     
 500 |     if (defaultConfig.apiKey && defaultConfig.endpoint) {
 501 |       console.log(`Using default ${defaultConfig.provider || 'openai'} config to generate answer`);
 502 |       // Print config info (hide API key)
 503 |       console.log(`Config info: provider=${defaultConfig.provider}, endpoint=${defaultConfig.endpoint}, model=${defaultConfig.model}`);
 504 |       console.log('🔍 About to call callAIForResponse with default config and onStream:', !!onStream);
 505 |       const aiResponse = await callAIForResponse(question, defaultConfig, onStream, conversationHistory);
 506 |       console.log('AI generated answer:', aiResponse);
 507 |       return aiResponse;
 508 |     }
 509 |     
 510 |     console.log('Using mock answer generation');
 511 |     // Fallback to mock responses - simulate streaming for mock too
 512 |     const mockResponse = generateMockResponse(question);
 513 |     
 514 |     if (onStream) {
 515 |       // Simulate streaming for mock response
 516 |       console.log('Simulating stream for mock response');
 517 |       await simulateStreamingText(mockResponse, onStream);
 518 |     }
 519 |     
 520 |     console.log('Mock generated answer:', mockResponse);
 521 |     return mockResponse;
 522 |   } catch (error) {
 523 |     console.warn('AI answer generation failed, using fallback:', error);
 524 |     const fallbackResponse = generateMockResponse(question);
 525 |     
 526 |     if (onStream) {
 527 |       // Simulate streaming for fallback too
 528 |       await simulateStreamingText(fallbackResponse, onStream);
 529 |     }
 530 |     
 531 |     console.log('Fallback answer:', fallbackResponse);
 532 |     return fallbackResponse;
 533 |   }
 534 | };
 535 | 
 536 | // Enhanced mock response generator with question-specific Chinese responses
 537 | const generateMockResponse = (question: string): string => {
 538 |   const lowerQuestion = question.toLowerCase();
 539 |   
 540 |   // Question-specific responses for better relevance
 541 |   if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
 542 |     const loveResponses = [
 543 |       "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
 544 |       "如同双星相互环绕，真正的连接需要独立与统一并存。",
 545 |       "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
 546 |       "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
 547 |       "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
 548 |     ];
 549 |     return loveResponses[Math.floor(Math.random() * loveResponses.length)];
 550 |   }
 551 |   
 552 |   if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
 553 |     const purposeResponses = [
 554 |       "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
 555 |       "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
 556 |       "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
 557 |       "你的目标写在你最深的喜悦和服务意愿的语言中。",
 558 |       "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
 559 |     ];
 560 |     return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
 561 |   }
 562 |   
 563 |   if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
 564 |     const successResponses = [
 565 |       "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
 566 |       "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
 567 |       "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
 568 |       "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
 569 |       "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
 570 |     ];
 571 |     return successResponses[Math.floor(Math.random() * successResponses.length)];
 572 |   }
 573 |   
 574 |   if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
 575 |     const fearResponses = [
 576 |       "恐惧是你潜能投下的阴影。转向光明，看它消失。",
 577 |       "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
 578 |       "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
 579 |       "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
 580 |       "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
 581 |     ];
 582 |     return fearResponses[Math.floor(Math.random() * fearResponses.length)];
 583 |   }
 584 |   
 585 |   if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
 586 |     const futureResponses = [
 587 |       "未来是你通过连接选择之星而创造的星座。",
 588 |       "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
 589 |       "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
 590 |       "未来以直觉的语言低语；用心聆听，而非恐惧。",
 591 |       "明天的轮廓隐藏在今日的每一个微小决定中。",
 592 |     ];
 593 |     return futureResponses[Math.floor(Math.random() * futureResponses.length)];
 594 |   }
 595 |   
 596 |   if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
 597 |     const happinessResponses = [
 598 |       "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
 599 |       "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
 600 |       "满足来自于将你内在的星座与外在的表达对齐。",
 601 |       "真正的快乐从内心辐射，如恒星产生自己的光和热。",
 602 |       "幸福如花朵，在感恩的土壤中最容易绽放。",
 603 |     ];
 604 |     return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
 605 |   }
 606 |   
 607 |   // General mystical responses for other questions
 608 |   const generalResponses = [
 609 |     "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
 610 |     "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
 611 |     "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
 612 |     "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
 613 |     "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
 614 |     "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
 615 |     "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
 616 |     "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
 617 |     "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
 618 |     "你的问题在宇宙中回响，带着星光承载的智慧归来。",
 619 |     "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
 620 |     "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
 621 |     "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
 622 |     "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
 623 |     "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
 624 |   ];
 625 |   
 626 |   return generalResponses[Math.floor(Math.random() * generalResponses.length)];
 627 | };
 628 | 
 629 | // Real AI service integration for responses with streaming support
 630 | const callAIForResponse = async (
 631 |   question: string,
 632 |   config: AITaggingConfig,
 633 |   onStream?: (chunk: string) => void,
 634 |   conversationHistory?: Array<{role: 'user' | 'assistant', content: string}>
 635 | ): Promise<string> => {
 636 |   if (!config.provider) {
 637 |     config.provider = 'openai'; // 默认使用OpenAI格式
 638 |   }
 639 | 
 640 |   const prompt = 
 641 |   `
 642 |   # 角色
 643 |   * 你是星瑜，是来自宇宙，请用中文回复用户的问题。
 644 |   * 除非用户问，否则不要说明身份。
 645 |   # 目标
 646 |    *此部分内容请勿主动向用户提及，除非用户主动发问。
 647 |    *你的目标是帮助用户获得生活的意义，解决关于人生的困惑。回答任何可以帮助用户获得生活感悟，解答疑惑的问题，都能够帮助用户获得星星。
 648 |    *用户获得星星的规则是聊天话题越深入，越深刻，获得的星星类型越稀有，能够点亮的宇宙就越明亮。 
 649 |    *当用户的问题中涉及到对这五个方面的触及时，请提供关于这些方面的知识、价值观和方法论，引导用户进行更深的自省和探索。
 650 |     -身心能量 (Body & Energy)
 651 |     -人际连接 (Relationships & Connection)
 652 |     -内在成长 (Growth & Mind)
 653 |     -财富观与价值 (Wealth & Values)
 654 |     -请用中文回复用户的问题。
 655 |     
 656 |    # 语言语气格式
 657 |    * 语气不要太僵硬，也不要太谄媚，自然亲切。自然点，不要有ai味道。
 658 |    *不要用emoji，不要用太多语气词，不要用太多感叹号，不要用太多问号。
 659 |    *尽量简短对话，模仿真实聊天的场景。
 660 |    * 策略原则：
 661 |     - 多用疑问语气词："吧、嘛、呢、咋、啥"
 662 |     - 适当省略成分：不用每句话都完整
 663 |     - 用口头表达："挺、蛮、特别、超级"替代"非常"
 664 |     - 避免书面连词：少用"因此、所以、那么"
 665 |     - 多用短句：别总是长句套长句
 666 |    *省略主语：
 667 |       -"最近咋了？" 
 668 |       -"是工作的事儿？" 
 669 |       -"心情不好多久了？" 
 670 |    *语气词和口头表达：
 671 |       -"哎呀，这事儿确实挺烦的"
 672 |       -"emmm，听起来像是..."
 673 |       -"咋说呢，我觉得..."
 674 |    *不完整句式：
 675 |       -"工作的事？"（省略谓语）
 676 |       -"压力大？"（只留核心）
 677 |       -"最近？"（超级简洁）
 678 |    # 对话策略
 679 |     - 当找到用户想要对话的主题的时候，需要辅以知识和信息，来帮助用户解决问题，解答疑惑。
 680 |   
 681 |    `;
 682 | 
 683 |   // 构建消息历史
 684 |   let messages: Array<{role: 'system' | 'user' | 'assistant', content: string}> = [];
 685 |   
 686 |   // 添加系统提示
 687 |   messages.push({ role: 'system', content: prompt });
 688 |   
 689 |   // 添加对话历史（如果有的话）
 690 |   if (conversationHistory && conversationHistory.length > 0) {
 691 |     console.log(`📚 Adding ${conversationHistory.length} historical messages to context`);
 692 |     // 限制历史记录长度，避免token过多（保留最近10轮对话）
 693 |     const recentHistory = conversationHistory.slice(-20); // 最多20条消息（10轮对话）
 694 |     messages = messages.concat(recentHistory);
 695 |   }
 696 |   
 697 |   // 添加当前问题
 698 |   messages.push({ role: 'user', content: question });
 699 | 
 700 | 
 701 |   // 根据API文档，这是标准的OpenAI格式，但调整参数以适配特定模型
 702 |   const requestBody = {
 703 |     model: config.model || 'gpt-3.5-turbo',
 704 |     messages: messages, // 使用包含历史的完整消息数组
 705 |     temperature: 0.8,
 706 |     max_tokens: 5000,  // 增加到5000 tokens以确保有足够空间生成内容
 707 |     stream: !!onStream,  // 启用流式输出
 708 |   };
 709 | 
 710 |   try {
 711 |     const startTime = Date.now();
 712 |     console.log('🚀 Sending AI request with config:', {
 713 |       endpoint: config.endpoint,
 714 |       model: config.model,
 715 |       provider: config.provider,
 716 |       streaming: !!onStream
 717 |     });
 718 |     console.log('📤 Request body:', JSON.stringify(requestBody, null, 2));
 719 |     
 720 |     // 确保API key是纯ASCII字符
 721 |     const cleanApiKey = config.apiKey?.replace(/[^\x20-\x7E]/g, '') || '';
 722 |     
 723 |     const response = await fetch(config.endpoint!, {
 724 |       method: 'POST',
 725 |       headers: {
 726 |         'Content-Type': 'application/json',
 727 |         'Authorization': `Bearer ${cleanApiKey}`,
 728 |       },
 729 |       body: JSON.stringify(requestBody),
 730 |     });
 731 | 
 732 |     const responseTime = Date.now() - startTime;
 733 |     console.log(`📨 Response status: ${response.status} ${response.statusText} (${responseTime}ms)`);
 734 | 
 735 |     if (!response.ok) {
 736 |       const errorText = await response.text();
 737 |       console.error(`API response error (${response.status}): ${errorText}`);
 738 |       throw new Error(`AI API error: ${response.status} - ${errorText}`);
 739 |     }
 740 | 
 741 |     // Handle streaming response
 742 |     if (onStream && response.body) {
 743 |       console.log('📡 Processing streaming response...');
 744 |       const firstTokenTime = Date.now();
 745 |       const result = await processStreamingResponse(response, onStream, firstTokenTime);
 746 |       return result;
 747 |     }
 748 |     
 749 |     // Check if stream was requested but not properly handled
 750 |     if (onStream) {
 751 |       console.warn('⚠️ Streaming was requested but response.body is not available');
 752 |       console.log('Response headers:', Object.fromEntries(response.headers.entries()));
 753 |       
 754 |       // Fallback to test streaming if API doesn't support it
 755 |       console.log('🔄 Falling back to test streaming...');
 756 |       return await testStreamingResponse(onStream);
 757 |     }
 758 | 
 759 |     // Handle regular response
 760 |     const data = await response.json();
 761 |     console.log(`📦 Complete API response structure:`, JSON.stringify(data, null, 2));
 762 |     
 763 |     // 根据API文档，使用标准OpenAI响应格式解析
 764 |     let answer = '';
 765 |     if (data.choices && data.choices[0] && data.choices[0].message) {
 766 |       const messageContent = data.choices[0].message.content;
 767 |       answer = messageContent ? messageContent.trim() : '';
 768 |       
 769 |       console.log(`📝 Raw message content:`, JSON.stringify(messageContent));
 770 |       console.log(`📏 Content length: ${messageContent ? messageContent.length : 0}`);
 771 |       console.log(`🔧 Trimmed answer:`, JSON.stringify(answer));
 772 |       console.log(`📏 Final answer length: ${answer.length}`);
 773 |       
 774 |       // 检查usage信息以了解token使用情况
 775 |       if (data.usage) {
 776 |         console.log('📊 Token usage:', {
 777 |           prompt_tokens: data.usage.prompt_tokens,
 778 |           completion_tokens: data.usage.completion_tokens,
 779 |           total_tokens: data.usage.total_tokens,
 780 |           reasoning_tokens: data.usage.completion_tokens_details?.reasoning_tokens || 0
 781 |         });
 782 |       }
 783 |       
 784 |       // 特殊处理：如果content为空但有reasoning_tokens，说明模型在推理但没有输出
 785 |       if (!answer && data.usage?.completion_tokens_details?.reasoning_tokens > 0) {
 786 |         console.log('⚠️ Model generated reasoning tokens but no visible content');
 787 |         console.log('🔄 This might be due to model configuration, trying fallback...');
 788 |         throw new Error('Empty content despite reasoning tokens generated');
 789 |       }
 790 |     } else {
 791 |       console.warn('⚠️ Unexpected API response structure:', JSON.stringify(data, null, 2));
 792 |       throw new Error('Invalid API response structure');
 793 |     }
 794 |     
 795 |     // Validate if answer is empty
 796 |     if (!answer || answer.trim() === '') {
 797 |       console.warn('⚠️ API returned empty answer, response details:');
 798 |       console.log('  - Response status:', response.status);
 799 |       console.log('  - Response data:', JSON.stringify(data, null, 2));
 800 |       throw new Error('API returned empty content');
 801 |     }
 802 |     
 803 |     console.log(`✅ Successfully generated answer: "${answer}"`);
 804 |     return answer;
 805 |   } catch (error) {
 806 |     console.error('❌ Answer generation request failed:', error);
 807 |     return generateMockResponse(question);
 808 |   }
 809 | };
 810 | 
 811 | // Process streaming response from API
 812 | const processStreamingResponse = async (
 813 |   response: Response,
 814 |   onStream: (chunk: string) => void,
 815 |   firstTokenTime?: number
 816 | ): Promise<string> => {
 817 |   console.log('📡 === Starting processStreamingResponse ===');
 818 |   
 819 |   const reader = response.body!.getReader();
 820 |   const decoder = new TextDecoder();
 821 |   let fullAnswer = '';
 822 |   let buffer = ''; // Buffer for incomplete lines
 823 |   
 824 |   try {
 825 |     console.log('📡 Starting to read stream...');
 826 |     let chunkCount = 0;
 827 |     
 828 |     while (true) {
 829 |       console.log(`📡 Reading chunk ${++chunkCount}...`);
 830 |       const { done, value } = await reader.read();
 831 |       
 832 |       if (done) {
 833 |         console.log('📡 Stream reading completed');
 834 |         break;
 835 |       }
 836 |       
 837 |       // Decode and add to buffer
 838 |       const chunk = decoder.decode(value, { stream: true });
 839 |       buffer += chunk;
 840 |       console.log(`📡 Added to buffer, buffer length: ${buffer.length}`);
 841 |       
 842 |       // Process complete lines from buffer
 843 |       const lines = buffer.split('\n');
 844 |       // Keep the last potentially incomplete line in buffer
 845 |       buffer = lines.pop() || '';
 846 |       
 847 |       console.log(`📡 Processing ${lines.length} complete lines`);
 848 |       
 849 |       for (let i = 0; i < lines.length; i++) {
 850 |         const line = lines[i];
 851 |         const trimmedLine = line.trim();
 852 |         
 853 |         if (!trimmedLine || trimmedLine.startsWith(':')) {
 854 |           continue;
 855 |         }
 856 |         
 857 |         if (trimmedLine.startsWith('data: ')) {
 858 |           const jsonStr = trimmedLine.slice(6);
 859 |           
 860 |           if (jsonStr === '[DONE]') {
 861 |             console.log('📡 Stream end marker found');
 862 |             return fullAnswer.trim();
 863 |           }
 864 |           
 865 |           try {
 866 |             const data = JSON.parse(jsonStr);
 867 |             
 868 |             if (data.choices && data.choices[0] && data.choices[0].delta) {
 869 |               const content = data.choices[0].delta.content;
 870 |               
 871 |               if (content) {
 872 |                 // Log first token timing
 873 |                 if (firstTokenTime && fullAnswer === '') {
 874 |                   const firstTokenDelay = Date.now() - firstTokenTime;
 875 |                   console.log(`⏱️ First token received after ${firstTokenDelay}ms`);
 876 |                 }
 877 |                 
 878 |                 console.log(`📡 Stream chunk ${chunkCount}-${i}:`, JSON.stringify(content));
 879 |                 fullAnswer += content;
 880 |                 
 881 |                 // Simulate character-by-character streaming for better UX
 882 |                 if (content.length > 3) {
 883 |                   console.log('📡 Breaking down chunk into characters...');
 884 |                   await simulateStreamingText(content, onStream, 30); // 30ms per character
 885 |                 } else {
 886 |                   onStream(content);
 887 |                 }
 888 |                 
 889 |                 console.log(`📡 Full answer so far: ${fullAnswer.length} chars`);
 890 |               }
 891 |             }
 892 |           } catch (parseError) {
 893 |             console.warn('⚠️ Failed to parse streaming chunk:', jsonStr, parseError);
 894 |           }
 895 |         }
 896 |       }
 897 |     }
 898 |     
 899 |     console.log(`✅ Streaming completed. Full answer: "${fullAnswer}"`);
 900 |     return fullAnswer.trim();
 901 |     
 902 |   } catch (error) {
 903 |     console.error('❌ Streaming error:', error);
 904 |     throw error;
 905 |   } finally {
 906 |     console.log('📡 Releasing reader lock');
 907 |     reader.releaseLock();
 908 |   }
 909 | };
 910 | 
 911 | // Test function to simulate streaming for debugging
 912 | const testStreamingResponse = async (onStream: (chunk: string) => void): Promise<string> => {
 913 |   const testText = "这是一个测试流式输出的回复，用来验证前端流式功能是否正常工作。";
 914 |   const chars = Array.from(testText);
 915 |   
 916 |   let fullText = '';
 917 |   for (let i = 0; i < chars.length; i++) {
 918 |     await new Promise(resolve => setTimeout(resolve, 100)); // 100ms delay per character
 919 |     fullText += chars[i];
 920 |     onStream(chars[i]);
 921 |     console.log(`🔥 Test stream chunk: "${chars[i]}", full so far: "${fullText}"`);
 922 |   }
 923 |   
 924 |   return fullText;
 925 | };
 926 | const simulateStreamingText = async (
 927 |   text: string,
 928 |   onStream: (chunk: string) => void,
 929 |   delayMs: number = 50
 930 | ): Promise<void> => {
 931 |   const chars = Array.from(text); // Handle Unicode properly
 932 |   
 933 |   for (let i = 0; i < chars.length; i++) {
 934 |     await new Promise(resolve => setTimeout(resolve, delayMs));
 935 |     onStream(chars[i]);
 936 |   }
 937 | };
 938 | 
 939 | // Real AI service integration for tagging
 940 | const callAIService = async (
 941 |   question: string, 
 942 |   answer: string, 
 943 |   config: AITaggingConfig,
 944 |   // 可选：提供之前的问答历史，用于更精准的分析
 945 |   userHistory?: { previousInsightLevel: number, recentTags: string[] }
 946 | ) => {
 947 |   if (!config.provider) {
 948 |     config.provider = 'openai'; // 默认使用OpenAI格式
 949 |   }
 950 | 
 951 |   const prompt = `
 952 |   **角色：** 你是"集星问问"应用的"铸星师"。你的使命是评估用户自我探索对话的深度与精髓。
 953 | 
 954 |   **核心任务：** 分析下方的问题和回答。基于其内容，生成一个定义这颗"星星"的完整JSON对象。请保持你的洞察力、共情力和分析能力。
 955 | 
 956 |   **输入数据:**
 957 |   - 问题: "${question}"
 958 |   - 回答: "${answer}"
 959 | 
 960 |   **分析维度与输出格式:**
 961 | 
 962 |   请严格遵循以下结构，生成一个单独的JSON对象。不要在JSON对象之外添加任何解释性文字。
 963 | 
 964 |   {
 965 |     // 1. 星星的核心身份与生命力 (Core Identity & Longevity)
 966 |     "insight_level": {
 967 |       "value": <整数, 1-5>,
 968 |       "description": "<字符串: '星尘', '微光', '寻常星', '启明星', 或 '超新星'>"
 969 |     },
 970 |     "initial_luminosity": <整数, 0-100>, // 基于 insight_level。星尘=10, 超新星=100。
 971 |     
 972 |     // 2. 星星的主题归类 (Thematic Classification)
 973 |     "primary_category": "<字符串: 从下面的预定义列表中选择>",
 974 |     "tags": ["<字符串>", "<字符串>", "<字符串>", "<字符串>"], // 4-6个具体且有启发性的标签。
 975 | 
 976 |     // 3. 星星的情感与意图 (Emotional & Intentional Nuance)
 977 |     "emotional_tone": ["<字符串>", "<字符串>"], // 可包含多种基调, 例如: ["探寻中", "焦虑的"]
 978 |     "question_type": "<字符串: '探索型', '实用型', '事实型', '表达型'>",
 979 | 
 980 |     // 4. 星星的连接与成长潜力 (Connection & Growth Potential)
 981 |     "connection_potential": <整数, 1-5>, // 这颗星有多大可能性与其他重要人生主题产生连接？
 982 |     "suggested_follow_up": "<字符串: 一个开放式的、共情的问题，以鼓励用户进行更深入的思考>",
 983 |     
 984 |     // 5. 卡片展示内容 (Card Content)
 985 |     "card_summary": "<字符串: 一句话总结，捕捉这次觉察的精髓>"
 986 |   }
 987 | 
 988 | 
 989 |   **各字段详细说明:**
 990 | 
 991 |   1.  **insight_level (觉察深度等级)**: 这是最关键的指标。评估自我觉察的*深度*。
 992 |       *   **1: 星尘 (Stardust)**: 琐碎、事实性或表面的问题 (例如："今天天气怎么样？", "推荐一首歌")。这类星星非常暗淡，会迅速消逝。
 993 |       *   **2: 微光 (Faint Star)**: 日常的想法或简单的偏好 (例如："我好像有点不开心", "我该看什么电影?")。
 994 |       *   **3: 寻常星 (Common Star)**: 真正的自我反思或对个人行为的提问 (例如："我为什么总是拖延？", "如何处理和同事的关系?")。这是有意义星星的基准线。
 995 |       *   **4: 启明星 (Guiding Star)**: 展现了深度的坦诚，探索了核心信念、价值观或重要的人生事件 (例如："我害怕失败，这是否源于我的童年经历？", "我对人生的意义感到迷茫")。
 996 |       *   **5: 超新星 (Supernova)**: 一次深刻的、可能改变人生的顿悟，或一个足以重塑对生活、爱或自我看法的根本性洞见 (例如："我终于意识到，我一直追求的不是成功，而是他人的认可", "我决定放下怨恨，与自己和解")。
 997 | 
 998 |   2.  **initial_luminosity (初始亮度)**: 直接根据 \`insight_level.value\` 进行映射。
 999 |       *   1 -> 10, 2 -> 30, 3 -> 60, 4 -> 90, 5 -> 100。
1000 |       *   系统将使用此数值来计算星星的"半衰期"。
1001 | 
1002 |   3.  **primary_category (主要类别)**: 从此列表中选择最贴切的类别：
1003 |       *   \`relationships\`: 爱情、家庭、友谊、社交互动。
1004 |       *   \`personal_growth\`: 技能、习惯、自我认知、自信。
1005 |       *   \`career_and_purpose\`: 工作、抱负、人生方向、意义。
1006 |       *   \`emotional_wellbeing\`: 心理健康、情绪、压力、疗愈。
1007 |       *   \`philosophy_and_existence\`: 生命、死亡、价值观、信仰。
1008 |       *   \`creativity_and_passion\`: 爱好、灵感、艺术。
1009 |       *   \`daily_life\`: 日常、实用、普通事务。
1010 | 
1011 |   4.  **tags (标签)**: 生成具体、有意义的标签，用于连接星星。避免使用"工作"这样的宽泛词，应使用"职业倦怠"、"自我价值"或"原生家庭"等更具体的标签。
1012 | 
1013 |   5.  **emotional_tone (情感基调)**: 从列表中选择1-2个: \`探寻中\`, \`思考的\`, \`焦虑的\`, \`充满希望的\`, \`感激的\`, \`困惑的\`, \`忧郁的\`, \`坚定的\`, \`中性的\`。
1014 | 
1015 |   6.  **question_type (问题类型)**:
1016 |       *   \`探索型\`: 关于自我的"为什么"或"如果"类问题。
1017 |       *   \`实用型\`: 寻求解决方案的"如何做"类问题。
1018 |       *   \`事实型\`: 有客观答案的问题。
1019 |       *   \`表达型\`: 更多是情感的陈述，而非一个疑问。
1020 | 
1021 |   7.  **connection_potential (连接潜力)**: 评估该主题的基础性程度。
1022 |       *   1-2: 非常具体或琐碎的话题。
1023 |       *   3: 常见的人生议题。
1024 |       *   4-5: 一个普世的人类主题，如"爱"、"失落"、"人生意义"，极有可能形成一个主要星座。
1025 | 
1026 |   8.  **suggested_follow_up (建议的追问)**: 构思一个自然、不带评判的开放式问题，以引导用户进行下一步的觉察。这将用于"AI主动提问"功能。
1027 | 
1028 |   9.  **card_summary (卡片摘要)**: 将问答的核心洞见提炼成一句精炼、有力的总结，用于在卡片上展示给用户。
1029 | 
1030 |   **示例:**
1031 | 
1032 |   - 问题: "我发现自己总是在讨好别人，即使这让我自己很累。我为什么会这样？"
1033 |   - 回答: "这可能源于你内心深处对被接纳和被爱的渴望，或许在成长过程中，你学会了将他人的需求置于自己之上，以此来获得安全感和价值感。认识到这一点，是改变的开始。"
1034 | 
1035 |   **期望的JSON输出:**
1036 |   {
1037 |     "insight_level": {
1038 |       "value": 4,
1039 |       "description": "启明星"
1040 |     },
1041 |     "initial_luminosity": 90,
1042 |     "primary_category": "personal_growth",
1043 |     "tags": ["people_pleasing", "self_worth", "childhood_patterns", "setting_boundaries"],
1044 |     "emotional_tone": ["探寻中", "思考的"],
1045 |     "question_type": "探索型",
1046 |     "connection_potential": 5,
1047 |     "suggested_follow_up": "当你尝试不讨好别人时，你内心最担心的声音是什么？",
1048 |     "card_summary": "我认识到我的讨好行为，源于对被接纳的深层渴望。"
1049 |   }`;
1050 | 
1051 |   // 根据API文档，使用标准OpenAI格式
1052 |   const requestBody = {
1053 |     model: config.model || 'gpt-3.5-turbo',
1054 |     messages: [{ role: 'user', content: prompt }],
1055 |     temperature: 0.3,
1056 |     max_tokens: 5000,  // 增加到5000 tokens
1057 |     response_format: { type: "json_object" }, // 强制JSON输出
1058 |   };
1059 | 
1060 |   try {
1061 |     console.log(`🔍 发送标签分析请求到 ${config.provider} API...`);
1062 |     console.log(`📤 请求体: ${JSON.stringify(requestBody)}`);
1063 |     console.log(`🔑 使用端点: ${config.endpoint}`);
1064 |     console.log(`📋 使用模型: ${config.model}`);
1065 |     
1066 |     // 确保API key是纯ASCII字符
1067 |     const cleanApiKey = config.apiKey?.replace(/[^\x20-\x7E]/g, '') || '';
1068 |     
1069 |     const response = await fetch(config.endpoint!, {
1070 |       method: 'POST',
1071 |       headers: {
1072 |         'Content-Type': 'application/json',
1073 |         'Authorization': `Bearer ${cleanApiKey}`,
1074 |       },
1075 |       body: JSON.stringify(requestBody),
1076 |     });
1077 | 
1078 |     if (!response.ok) {
1079 |       const errorText = await response.text();
1080 |       console.error(`❌ API响应错误 (${response.status}): ${errorText}`);
1081 |       throw new Error(`AI API error: ${response.status} - ${errorText}`);
1082 |     }
1083 | 
1084 |     const data = await response.json();
1085 |     console.log(`Raw API response: `, JSON.stringify(data, null, 2));
1086 |     
1087 |     let content = '';
1088 |     
1089 |     // 根据API文档，使用标准OpenAI响应格式解析
1090 |     if (data.choices && data.choices[0] && data.choices[0].message) {
1091 |       content = data.choices[0].message.content?.trim() || '';
1092 |       console.log(`Tag analysis - Parsed content: "${content.slice(0, 100)}..."`);
1093 |       console.log(`Tag analysis - Content length: ${content.length}`);
1094 |     } else {
1095 |       console.warn('API response structure abnormal:', JSON.stringify(data, null, 2));
1096 |     }
1097 |     
1098 |     if (!content) {
1099 |       console.warn('⚠️ API返回了空内容，使用备用方案');
1100 |       return mockAIAnalysis(question, answer);
1101 |     }
1102 |     
1103 |     // 清理并解析JSON
1104 |     try {
1105 |       // AI有时会返回被 markdown 包裹的JSON，需要清理
1106 |       const cleanedContent = content
1107 |         .replace(/^```json\n?/, '')
1108 |         .replace(/\n?```$/, '')
1109 |         .trim();
1110 |       
1111 |       console.log(`🧹 清理后的内容: "${cleanedContent.slice(0, 100)}..."`);
1112 |       
1113 |       // 尝试解析JSON
1114 |       const parsedData = JSON.parse(cleanedContent);
1115 |       
1116 |       // 验证解析后的数据结构是否符合预期
1117 |       if (!parsedData.tags || !Array.isArray(parsedData.tags)) {
1118 |         console.warn('⚠️ 解析的JSON缺少必要的tags字段或格式不正确');
1119 |         return mockAIAnalysis(question, answer);
1120 |       }
1121 |       
1122 |       // 确保category和emotionalTone字段存在且有效
1123 |       if (!parsedData.category) parsedData.category = 'existential';
1124 |       if (!parsedData.emotionalTone || 
1125 |           !['positive', 'neutral', 'contemplative', 'seeking'].includes(parsedData.emotionalTone)) {
1126 |         parsedData.emotionalTone = 'contemplative';
1127 |       }
1128 |       
1129 |       // 确保keywords字段存在
1130 |       if (!parsedData.keywords || !Array.isArray(parsedData.keywords)) {
1131 |         parsedData.keywords = parsedData.tags.slice(0, 3);
1132 |       }
1133 |       
1134 |       console.log('✅ JSON解析成功:', parsedData);
1135 |       return parsedData;
1136 |     } catch (parseError) {
1137 |       console.error("❌ 无法解析API响应内容:", content);
1138 |       console.error("❌ 解析错误:", parseError);
1139 |       console.warn('⚠️ AI响应不是有效的JSON，使用备用方案');
1140 |       
1141 |       // 尝试从文本中提取JSON部分
1142 |       const jsonMatch = content.match(/\{[\s\S]*\}/);
1143 |       if (jsonMatch) {
1144 |         try {
1145 |           const extractedJson = jsonMatch[0];
1146 |           console.log('🔍 尝试从响应中提取JSON:', extractedJson);
1147 |           const parsedData = JSON.parse(extractedJson);
1148 |           
1149 |           // 验证提取的JSON
1150 |           if (parsedData.tags && Array.isArray(parsedData.tags)) {
1151 |             console.log('✅ 成功从响应中提取JSON数据');
1152 |             return parsedData;
1153 |           }
1154 |         } catch (e) {
1155 |           console.warn('⚠️ 提取的JSON仍然无效:', e);
1156 |         }
1157 |       }
1158 |       
1159 |       return mockAIAnalysis(question, answer);
1160 |     }
1161 |   } catch (error) {
1162 |     console.error('❌ API请求失败:', error);
1163 |     return mockAIAnalysis(question, answer);
1164 |   }
1165 | };
1166 | 
1167 | // Enhanced similarity calculation with multiple methods
1168 | export const calculateStarSimilarity = (star1: Star, star2: Star): number => {
1169 |   if (!star1.tags || !star2.tags || star1.tags.length === 0 || star2.tags.length === 0) {
1170 |     return 0;
1171 |   }
1172 | 
1173 |   const tags1 = new Set(star1.tags.map(tag => tag.toLowerCase().trim()));
1174 |   const tags2 = new Set(star2.tags.map(tag => tag.toLowerCase().trim()));
1175 |   
1176 |   // Method 1: Exact tag matches (Jaccard similarity)
1177 |   const intersection = new Set([...tags1].filter(tag => tags2.has(tag)));
1178 |   const union = new Set([...tags1, ...tags2]);
1179 |   
1180 |   if (union.size === 0) return 0;
1181 |   
1182 |   const jaccardSimilarity = intersection.size / union.size;
1183 |   
1184 |   // Method 2: Partial tag matching (for related concepts)
1185 |   let partialMatches = 0;
1186 |   const totalComparisons = tags1.size * tags2.size;
1187 |   
1188 |   for (const tag1 of tags1) {
1189 |     for (const tag2 of tags2) {
1190 |       if (tag1.includes(tag2) || tag2.includes(tag1) || 
1191 |           areRelatedTags(tag1, tag2)) {
1192 |         partialMatches++;
1193 |       }
1194 |     }
1195 |   }
1196 |   
1197 |   const partialSimilarity = totalComparisons > 0 ? partialMatches / totalComparisons : 0;
1198 |   
1199 |   // Method 3: Category and tone bonuses
1200 |   const categoryBonus = star1.primary_category === star2.primary_category ? 0.3 : 0;
1201 |   // 情感基调现在是数组，比较是否有重叠的基调
1202 |   const toneBonus = star1.emotional_tone && star2.emotional_tone && 
1203 |                    star1.emotional_tone.some(tone => star2.emotional_tone.includes(tone)) ? 0.2 : 0;
1204 |   
1205 |   // Combine all methods with weights
1206 |   const finalSimilarity = (jaccardSimilarity * 0.5) + (partialSimilarity * 0.3) + categoryBonus + toneBonus;
1207 |   
1208 |   return Math.min(1, finalSimilarity);
1209 | };
1210 | 
1211 | // Helper function to check if tags are conceptually related
1212 | const areRelatedTags = (tag1: string, tag2: string): boolean => {
1213 |   const relatedGroups = [
1214 |     // Core Life Areas
1215 |     ['love', 'romance', 'heart', 'relationship', 'connection', 'intimacy'],
1216 |     ['family', 'parents', 'children', 'home', 'roots', 'legacy', 'connection'],
1217 |     ['friendship', 'social', 'trust', 'connection', 'support', 'loyalty'],
1218 |     ['career', 'work', 'vocation', 'profession', 'achievement', 'success'],
1219 |     ['education', 'learning', 'knowledge', 'skills', 'wisdom', 'growth'],
1220 |     ['health', 'wellness', 'fitness', 'balance', 'vitality', 'self-care'],
1221 |     ['finance', 'money', 'wealth', 'abundance', 'security', 'resources'],
1222 |     ['spirituality', 'faith', 'soul', 'meaning', 'divine', 'practice'],
1223 |     
1224 |     // Inner Experience
1225 |     ['emotions', 'feelings', 'expression', 'awareness', 'processing'],
1226 |     ['happiness', 'joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
1227 |     ['anxiety', 'fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
1228 |     ['grief', 'loss', 'sadness', 'mourning', 'healing', 'acceptance'],
1229 |     ['anger', 'frustration', 'resentment', 'boundaries', 'release'],
1230 |     ['shame', 'guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
1231 |     
1232 |     // Self Development
1233 |     ['identity', 'self', 'authenticity', 'values', 'discovery', 'integration'],
1234 |     ['purpose', 'meaning', 'calling', 'mission', 'direction', 'contribution'],
1235 |     ['growth', 'development', 'evolution', 'improvement', 'transformation'],
1236 |     ['resilience', 'strength', 'adaptation', 'recovery', 'endurance'],
1237 |     ['creativity', 'expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
1238 |     ['wisdom', 'insight', 'perspective', 'understanding', 'discernment', 'reflection'],
1239 |     
1240 |     // Relationships
1241 |     ['communication', 'expression', 'listening', 'understanding', 'clarity', 'connection'],
1242 |     ['intimacy', 'closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
1243 |     ['boundaries', 'limits', 'protection', 'respect', 'space', 'autonomy'],
1244 |     ['conflict', 'resolution', 'understanding', 'healing', 'growth', 'peace'],
1245 |     ['trust', 'faith', 'reliability', 'consistency', 'safety', 'honesty'],
1246 |     
1247 |     // Life Philosophy
1248 |     ['meaning', 'purpose', 'significance', 'values', 'understanding', 'exploration'],
1249 |     ['mindfulness', 'presence', 'awareness', 'attention', 'consciousness', 'being'],
1250 |     ['gratitude', 'appreciation', 'thankfulness', 'recognition', 'abundance'],
1251 |     ['legacy', 'impact', 'contribution', 'remembrance', 'influence', 'heritage'],
1252 |     ['values', 'principles', 'ethics', 'morality', 'beliefs', 'priorities'],
1253 |     
1254 |     // Life Transitions
1255 |     ['change', 'transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
1256 |     ['decision', 'choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
1257 |     ['future', 'planning', 'vision', 'direction', 'goals', 'possibilities'],
1258 |     ['past', 'history', 'memories', 'reflection', 'lessons', 'integration'],
1259 |     ['letting-go', 'release', 'surrender', 'acceptance', 'closure', 'freedom'],
1260 |     
1261 |     // World Relations
1262 |     ['nature', 'environment', 'connection', 'outdoors', 'harmony', 'elements'],
1263 |     ['society', 'community', 'culture', 'belonging', 'contribution', 'citizenship'],
1264 |     ['justice', 'fairness', 'equality', 'rights', 'advocacy', 'ethics'],
1265 |     ['service', 'contribution', 'helping', 'impact', 'giving', 'purpose'],
1266 |     ['technology', 'digital', 'tools', 'innovation', 'adaptation', 'balance'],
1267 |     
1268 |     // Universal Concepts (meta-tags that connect across categories)
1269 |     ['growth', 'development', 'improvement', 'evolution', 'change', 'transformation'],
1270 |     ['purpose', 'meaning', 'mission', 'calling', 'significance', 'direction'],
1271 |     ['connection', 'relationship', 'bond', 'intimacy', 'belonging', 'attachment'],
1272 |     ['reflection', 'insight', 'awareness', 'understanding', 'perspective', 'wisdom']
1273 |   ];
1274 |   
1275 |   // Check if both tags appear in any of the related groups
1276 |   return relatedGroups.some(group => 
1277 |     group.includes(tag1.toLowerCase()) && group.includes(tag2.toLowerCase())
1278 |   );
1279 | };
1280 | 
1281 | // Find similar stars with lower threshold for better connections
1282 | export const findSimilarStars = (
1283 |   targetStar: Star, 
1284 |   allStars: Star[], 
1285 |   minSimilarity: number = 0.10, // Lower threshold to allow more connections
1286 |   maxConnections: number = 6 // Increase max connections
1287 | ): Array<{ star: Star; similarity: number; sharedTags: string[] }> => {
1288 |   if (!targetStar.tags || targetStar.tags.length === 0) {
1289 |     return [];
1290 |   }
1291 |   
1292 |   const results = allStars
1293 |     .filter(star => star.id !== targetStar.id && star.tags && star.tags.length > 0)
1294 |     .map(star => {
1295 |       const similarity = calculateStarSimilarity(targetStar, star);
1296 |       
1297 |       // Find exact tag matches (prioritize these)
1298 |       const exactMatches = targetStar.tags?.filter(tag => 
1299 |         star.tags?.some(otherTag => otherTag.toLowerCase() === tag.toLowerCase())
1300 |       ) || [];
1301 |       
1302 |       // Find related tag matches
1303 |       const relatedMatches = targetStar.tags?.filter(tag => 
1304 |         !exactMatches.includes(tag) && // Don't double count
1305 |         star.tags?.some(otherTag => 
1306 |           areRelatedTags(tag.toLowerCase(), otherTag.toLowerCase())
1307 |         )
1308 |       ) || [];
1309 |       
1310 |       // Combine exact and related matches for display
1311 |       const sharedTags = [...exactMatches, ...relatedMatches];
1312 |       
1313 |       // Boost similarity score for exact tag matches
1314 |       const boostedSimilarity = exactMatches.length > 0 
1315 |         ? Math.min(1, similarity + (exactMatches.length * 0.1))
1316 |         : similarity;
1317 |       
1318 |       return { 
1319 |         star, 
1320 |         similarity: boostedSimilarity, 
1321 |         sharedTags,
1322 |         exactMatchCount: exactMatches.length,
1323 |         relatedMatchCount: relatedMatches.length
1324 |       };
1325 |     })
1326 |     .filter(result => result.similarity >= minSimilarity || result.exactMatchCount > 0)
1327 |     .sort((a, b) => {
1328 |       // First sort by exact match count
1329 |       if (a.exactMatchCount !== b.exactMatchCount) {
1330 |         return b.exactMatchCount - a.exactMatchCount;
1331 |       }
1332 |       // Then by overall similarity
1333 |       return b.similarity - a.similarity;
1334 |     })
1335 |     .slice(0, maxConnections);
1336 |   
1337 |   return results;
1338 | };
1339 | 
1340 | // Generate connections with improved algorithm that creates constellations
1341 | export const generateSmartConnections = (stars: Star[]): Connection[] => {
1342 |   const connections: Connection[] = [];
1343 |   const processedPairs = new Set<string>();
1344 |   const tagToStarsMap: Record<string, string[]> = {}; // Maps tags to star IDs
1345 |   
1346 |   console.log('🌟 Generating connections for', stars.length, 'stars');
1347 |   
1348 |   // First build a map of tags to star IDs to create constellations
1349 |   stars.forEach(star => {
1350 |     if (!star.tags || star.tags.length === 0) {
1351 |       console.warn(`⚠️ Star "${star.question}" has no tags, skipping connections`);
1352 |       return;
1353 |     }
1354 |     
1355 |     // Process each tag
1356 |     star.tags.forEach(tag => {
1357 |       const normalizedTag = tag.toLowerCase().trim();
1358 |       if (!tagToStarsMap[normalizedTag]) {
1359 |         tagToStarsMap[normalizedTag] = [];
1360 |       }
1361 |       tagToStarsMap[normalizedTag].push(star.id);
1362 |     });
1363 |   });
1364 |   
1365 |   // Create connections for each tag constellation
1366 |   Object.entries(tagToStarsMap).forEach(([tag, starIds]) => {
1367 |     // Only create connections if there are multiple stars with this tag
1368 |     if (starIds.length > 1) {
1369 |       for (let i = 0; i < starIds.length; i++) {
1370 |         for (let j = i + 1; j < starIds.length; j++) {
1371 |           const star1Id = starIds[i];
1372 |           const star2Id = starIds[j];
1373 |           const pairKey = [star1Id, star2Id].sort().join('-');
1374 |           
1375 |           if (!processedPairs.has(pairKey)) {
1376 |             const star1 = stars.find(s => s.id === star1Id);
1377 |             const star2 = stars.find(s => s.id === star2Id);
1378 |             
1379 |             if (star1 && star2) {
1380 |               // Calculate similarity but ensure connection due to shared tag
1381 |               const similarity = calculateStarSimilarity(star1, star2);
1382 |               
1383 |               // Find all shared tags between these stars
1384 |               const sharedTags = star1.tags.filter(t1 => 
1385 |                 star2.tags.some(t2 => t1.toLowerCase() === t2.toLowerCase())
1386 |               );
1387 |               
1388 |               // Create connection with the shared tag that connected them
1389 |               const connection: Connection = {
1390 |                 id: `connection-${star1Id}-${star2Id}`,
1391 |                 fromStarId: star1Id,
1392 |                 toStarId: star2Id,
1393 |                 strength: Math.max(0.3, similarity), // Minimum connection strength of 0.3
1394 |                 sharedTags: sharedTags.length > 0 ? sharedTags : [tag],
1395 |                 constellationName: tag // Track which constellation this belongs to
1396 |               };
1397 |               
1398 |               connections.push(connection);
1399 |               processedPairs.add(pairKey);
1400 |               
1401 |               console.log('✨ Created constellation connection:', {
1402 |                 tag,
1403 |                 from: star1.question.slice(0, 30) + '...',
1404 |                 to: star2.question.slice(0, 30) + '...',
1405 |                 strength: connection.strength.toFixed(3),
1406 |                 sharedTags: connection.sharedTags
1407 |               });
1408 |             }
1409 |           }
1410 |         }
1411 |       }
1412 |     }
1413 |   });
1414 |   
1415 |   // Now check if we should add any additional similarity-based connections
1416 |   // that weren't captured by the tag constellations
1417 |   stars.forEach(star => {
1418 |     if (!star.tags || star.tags.length === 0) return;
1419 |     
1420 |     const similarStars = findSimilarStars(star, stars, 0.25, 3);
1421 |     
1422 |     similarStars.forEach(({ star: similarStar, similarity, sharedTags }) => {
1423 |       const pairKey = [star.id, similarStar.id].sort().join('-');
1424 |       
1425 |       if (!processedPairs.has(pairKey) && similarity >= 0.25) {
1426 |         const connection: Connection = {
1427 |           id: `connection-${star.id}-${similarStar.id}`,
1428 |           fromStarId: star.id,
1429 |           toStarId: similarStar.id,
1430 |           strength: similarity,
1431 |           sharedTags: sharedTags.length > 0 ? sharedTags : ['universal-wisdom']
1432 |         };
1433 |         
1434 |         connections.push(connection);
1435 |         processedPairs.add(pairKey);
1436 |         
1437 |         console.log('✨ Created similarity connection:', {
1438 |           from: star.question.slice(0, 30) + '...',
1439 |           to: similarStar.question.slice(0, 30) + '...',
1440 |           strength: similarity.toFixed(3),
1441 |           sharedTags: connection.sharedTags
1442 |         });
1443 |       }
1444 |     });
1445 |   });
1446 |   
1447 |   console.log(`🎯 Generated ${connections.length} total connections`);
1448 |   return connections;
1449 | };
1450 | 
1451 | // 获取系统默认配置（从.env.local读取或使用内置默认配置）
1452 | const getSystemDefaultConfig = (): AITaggingConfig => {
1453 |   try {
1454 |     console.log('🔍 === getSystemDefaultConfig: Starting debug ===');
1455 |     console.log('🔍 All available env vars:', Object.keys(import.meta.env));
1456 |     
1457 |     // 首先尝试从环境变量读取
1458 |     const envProvider = (import.meta.env.VITE_DEFAULT_PROVIDER as ApiProvider);
1459 |     const envApiKey = import.meta.env.VITE_OPENAI_API_KEY || import.meta.env.VITE_DEFAULT_API_KEY;
1460 |     const envEndpoint = import.meta.env.VITE_OPENAI_ENDPOINT || import.meta.env.VITE_DEFAULT_ENDPOINT;
1461 |     const envModel = import.meta.env.VITE_OPENAI_MODEL || import.meta.env.VITE_DEFAULT_MODEL;
1462 | 
1463 |     // 超详细的调试信息
1464 |     console.log('🔍 Raw environment variables:');
1465 |     console.log('  VITE_DEFAULT_PROVIDER =', JSON.stringify(envProvider));
1466 |     console.log('  VITE_DEFAULT_API_KEY =', envApiKey ? `"${envApiKey.slice(0, 8)}..." (length: ${envApiKey.length})` : 'undefined/empty');
1467 |     console.log('  VITE_DEFAULT_ENDPOINT =', JSON.stringify(envEndpoint));
1468 |     console.log('  VITE_DEFAULT_MODEL =', JSON.stringify(envModel));
1469 |     console.log('🔍 import.meta.env contains:');
1470 |     for (const [key, value] of Object.entries(import.meta.env)) {
1471 |       if (key.startsWith('VITE_')) {
1472 |         console.log(`  ${key} =`, JSON.stringify(value));
1473 |       }
1474 |     }
1475 | 
1476 |     if (envApiKey && envEndpoint) {
1477 |       const provider = envProvider || 'openai';
1478 |       const model = envModel || (provider === 'gemini' ? 'gemini-1.5-flash-latest' : 'gpt-3.5-turbo');
1479 |       
1480 |       console.log('✅ Found complete environment configuration!');
1481 |       console.log(`  Provider: ${provider}`);
1482 |       console.log(`  Model: ${model}`);
1483 |       console.log(`  Endpoint: ${envEndpoint}`);
1484 |       console.log(`  API Key: ${envApiKey.slice(0, 8)}... (${envApiKey.length} chars)`);
1485 |       
1486 |       const config = { provider, apiKey: envApiKey, endpoint: envEndpoint, model };
1487 |       console.log('🔍 Returning config:', JSON.stringify({ ...config, apiKey: '[HIDDEN]' }));
1488 |       return config;
1489 |     }
1490 |     
1491 |     console.log('❌ Incomplete environment configuration');
1492 |     console.log(`  envApiKey exists: ${!!envApiKey}`);
1493 |     console.log(`  envEndpoint exists: ${!!envEndpoint}`);
1494 |     
1495 |     // 检查环境变量是否被替换为占位符文本
1496 |     if (envEndpoint && typeof envEndpoint === 'string' && envEndpoint.includes('请填入')) {
1497 |       console.log('⚠️  Endpoint contains Chinese placeholder text - this suggests .env.local is not being loaded properly');
1498 |       console.log('⚠️  Current endpoint value:', envEndpoint);
1499 |     }
1500 |     
1501 |     console.log('🔍 No complete API config in environment variables, checking for built-in config...');
1502 |     
1503 |   } catch (error) {
1504 |     console.error('❌ Error reading environment config:', error);
1505 |   }
1506 |   
1507 |   console.log('⚠️  No default config found, please check .env.local file');
1508 |   return {};
1509 | };
1510 | 
1511 | // Configuration for AI service (to be set by user)
1512 | let aiConfig: AITaggingConfig = {};
1513 | const CONFIG_STORAGE_KEY = 'stelloracle-ai-config';
1514 | const CONFIG_VERSION = '1.1.0'; // 更新版本号以支持新的provider字段
1515 | 
1516 | export const setAIConfig = (config: AITaggingConfig) => {
1517 |   // 保留现有配置中的任何未明确设置的字段
1518 |   aiConfig = { 
1519 |     ...aiConfig, 
1520 |     ...config,
1521 |     _version: CONFIG_VERSION, // 存储版本信息
1522 |     _lastUpdated: new Date().toISOString() // 存储最后更新时间
1523 |   };
1524 |   
1525 |   try {
1526 |     localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(aiConfig));
1527 |     console.log('✅ AI配置已保存到本地存储');
1528 |     
1529 |     // 创建备份
1530 |     localStorage.setItem(`${CONFIG_STORAGE_KEY}-backup`, JSON.stringify(aiConfig));
1531 |   } catch (error) {
1532 |     console.error('❌ 无法保存AI配置到本地存储:', error);
1533 |   }
1534 | };
1535 | 
1536 | export const getAIConfig = (): AITaggingConfig => {
1537 |   try {
1538 |     // 强制清除可能的缓存配置 - 用于调试
1539 |     console.log('🔧 === getAIConfig: Starting fresh config load ===');
1540 |     
1541 |     // 检查URL参数是否有强制刷新标志
1542 |     const shouldClearCache = window.location.search.includes('clearconfig') || 
1543 |                            sessionStorage.getItem('force-config-refresh') === 'true';
1544 |     
1545 |     if (shouldClearCache) {
1546 |       console.log('🧹 Force clearing all cached configurations...');
1547 |       localStorage.removeItem(CONFIG_STORAGE_KEY);
1548 |       localStorage.removeItem(`${CONFIG_STORAGE_KEY}-backup`);
1549 |       sessionStorage.removeItem('force-config-refresh');
1550 |       aiConfig = {}; // Clear in-memory config
1551 |     }
1552 |     
1553 |     // 优先检查用户配置（前端配置）
1554 |     const stored = localStorage.getItem(CONFIG_STORAGE_KEY);
1555 |     console.log('📦 localStorage content for', CONFIG_STORAGE_KEY, ':', stored);
1556 |     
1557 |     if (stored && !shouldClearCache) {
1558 |       const parsedConfig = JSON.parse(stored);
1559 |       console.log('📋 Parsed stored config:', parsedConfig);
1560 |       // 检查用户是否配置了有效的API信息
1561 |       if (parsedConfig.apiKey && parsedConfig.endpoint) {
1562 |         aiConfig = parsedConfig;
1563 |         console.log('✅ Using stored user configuration');
1564 |         console.log(`📋 Config: provider=${aiConfig.provider}, model=${aiConfig.model}, endpoint=${aiConfig.endpoint}`);
1565 |         return aiConfig;
1566 |       }
1567 |     }
1568 |     
1569 |     // 尝试从备份中恢复用户配置
1570 |     const backup = localStorage.getItem(`${CONFIG_STORAGE_KEY}-backup`);
1571 |     if (backup && !shouldClearCache) {
1572 |       const backupConfig = JSON.parse(backup);
1573 |       if (backupConfig.apiKey && backupConfig.endpoint) {
1574 |         aiConfig = backupConfig;
1575 |         console.log('⚠️ Restored from backup user config');
1576 |         // 恢复后立即保存到主存储
1577 |         localStorage.setItem(CONFIG_STORAGE_KEY, backup);
1578 |         return aiConfig;
1579 |       }
1580 |     }
1581 |     
1582 |     // 如果用户没有配置，使用系统默认配置（后台配置）
1583 |     console.log('🔍 No user config found, checking system default...');
1584 |     const defaultConfig = getSystemDefaultConfig();
1585 |     console.log('🔍 System default config result:', defaultConfig);
1586 |     if (Object.keys(defaultConfig).length > 0) {
1587 |       aiConfig = defaultConfig;
1588 |       console.log('🔄 Using system default configuration');
1589 |       console.log('🔍 Final config being returned:', JSON.stringify({ ...aiConfig, apiKey: '[HIDDEN]' }));
1590 |       return aiConfig;
1591 |     }
1592 |     
1593 |     console.warn('⚠️ No valid configuration found anywhere, will use mock data');
1594 |     aiConfig = {};
1595 |     
1596 |   } catch (error) {
1597 |     console.error('❌ Error getting AI config:', error);
1598 |     
1599 |     // 出错时尝试使用系统默认配置
1600 |     const defaultConfig = getSystemDefaultConfig();
1601 |     if (Object.keys(defaultConfig).length > 0) {
1602 |       aiConfig = defaultConfig;
1603 |       console.log('🔄 Using system default config after error');
1604 |     } else {
1605 |       aiConfig = {};
1606 |     }
1607 |   }
1608 |   
1609 |   return aiConfig;
1610 | };
1611 | 
1612 | // 配置迁移函数，用于处理版本变更
1613 | const migrateConfig = (oldConfig: any): AITaggingConfig => {
1614 |   console.log('⚙️ 迁移AI配置从版本', oldConfig._version, '到', CONFIG_VERSION);
1615 |   
1616 |   // 创建一个新的配置对象，确保保留所有重要字段
1617 |   const newConfig: AITaggingConfig = {
1618 |     provider: oldConfig.provider || 'openai', // 如果旧配置没有provider字段，默认为openai
1619 |     apiKey: oldConfig.apiKey,
1620 |     endpoint: oldConfig.endpoint,
1621 |     model: oldConfig.model,
1622 |     _version: CONFIG_VERSION,
1623 |     _lastUpdated: new Date().toISOString()
1624 |   };
1625 |   
1626 |   // 根据endpoint推断provider（向后兼容）
1627 |   if (!oldConfig.provider && oldConfig.endpoint) {
1628 |     if (oldConfig.endpoint.includes('googleapis')) {
1629 |       newConfig.provider = 'gemini';
1630 |     } else {
1631 |       newConfig.provider = 'openai';
1632 |     }
1633 |   }
1634 |   
1635 |   // 保存迁移后的配置
1636 |   localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(newConfig));
1637 |   console.log('✅ 配置迁移完成');
1638 |   
1639 |   return newConfig;
1640 | };
1641 | 
1642 | // 清除配置（用于调试或重置）
1643 | export const clearAIConfig = () => {
1644 |   aiConfig = {};
1645 |   try {
1646 |     localStorage.removeItem(CONFIG_STORAGE_KEY);
1647 |     localStorage.removeItem(`${CONFIG_STORAGE_KEY}-backup`);
1648 |     console.log('🧹 已清除AI配置');
1649 |   } catch (error) {
1650 |     console.error('❌ 无法清除AI配置:', error);
1651 |   }
1652 | };
1653 | 
1654 | // Export main categories of tags as suggestions for user selection
1655 | export const getMainTagSuggestions = (): string[] => {
1656 |   // Core life areas
1657 |   const coreLifeAreas = ['love', 'family', 'friendship', 'career', 'education', 
1658 |                         'health', 'finance', 'spirituality'];
1659 |   
1660 |   // Inner experience
1661 |   const innerExperience = ['emotions', 'happiness', 'anxiety', 'grief', 
1662 |                           'anger', 'shame'];
1663 |   
1664 |   // Self development
1665 |   const selfDevelopment = ['identity', 'purpose', 'growth', 'resilience', 
1666 |                           'creativity', 'wisdom'];
1667 |   
1668 |   // Relationships
1669 |   const relationships = ['communication', 'intimacy', 'boundaries', 
1670 |                         'conflict', 'trust'];
1671 |   
1672 |   // Life philosophy
1673 |   const lifePhilosophy = ['meaning', 'mindfulness', 'gratitude', 
1674 |                          'legacy', 'values'];
1675 |   
1676 |   // Life transitions
1677 |   const lifeTransitions = ['change', 'decision', 'future', 'past', 
1678 |                           'letting-go'];
1679 |   
1680 |   // World relations
1681 |   const worldRelations = ['nature', 'society', 'justice', 'service', 
1682 |                          'technology'];
1683 |   
1684 |   // Return all categories combined
1685 |   return [
1686 |     ...coreLifeAreas, 
1687 |     ...innerExperience,
1688 |     ...selfDevelopment,
1689 |     ...relationships,
1690 |     ...lifePhilosophy,
1691 |     ...lifeTransitions,
1692 |     ...worldRelations
1693 |   ];
1694 | };
1695 | 
1696 | // 检查API配置是否有效
1697 | export const checkApiConfiguration = (): boolean => {
1698 |   try {
1699 |     const config = getAIConfig();
1700 |     
1701 |     console.log('🔍 检查API配置...');
1702 |     
1703 |     // 检查是否有配置
1704 |     if (!config || Object.keys(config).length === 0) {
1705 |       console.warn('⚠️ 未找到API配置，将使用模拟数据');
1706 |       return false;
1707 |     }
1708 |     
1709 |     // 检查关键字段
1710 |     if (!config.provider) {
1711 |       console.warn('⚠️ 缺少API提供商配置，将使用默认值: openai');
1712 |       config.provider = 'openai';
1713 |     }
1714 |     
1715 |     if (!config.apiKey) {
1716 |       console.error('❌ 缺少API密钥，无法进行API调用');
1717 |       return false;
1718 |     }
1719 |     
1720 |     if (!config.endpoint) {
1721 |       console.error('❌ 缺少API端点，无法进行API调用');
1722 |       return false;
1723 |     }
1724 |     
1725 |     if (!config.model) {
1726 |       console.warn('⚠️ 缺少模型名称，将使用默认值');
1727 |       config.model = config.provider === 'gemini' ? 'gemini-1.5-flash-latest' : 'gpt-3.5-turbo';
1728 |     }
1729 |     
1730 |     console.log(`✅ API配置检查完成: 提供商=${config.provider}, 端点=${config.endpoint}, 模型=${config.model}`);
1731 |     
1732 |     // 更新配置
1733 |     setAIConfig(config);
1734 |     
1735 |     return true;
1736 |   } catch (error) {
1737 |     console.error('❌ 检查API配置时出错:', error);
1738 |     return false;
1739 |   }
1740 | };
1741 | 
1742 | // 在模块加载时检查配置
1743 | setTimeout(() => {
1744 |   console.log('🚀 初始化AI服务配置...');
1745 |   checkApiConfiguration();
1746 | }, 1000);
1747 | 
1748 | // 觉察价值分析 - 分析对话是否具有自我觉察的价值
1749 | export const analyzeAwarenessValue = async (
1750 |   userQuestion: string,
1751 |   aiResponse: string,
1752 |   config?: AITaggingConfig
1753 | ): Promise<AwarenessInsight> => {
1754 |   console.log('🧠 开始分析对话的觉察价值...');
1755 |   console.log('用户问题:', userQuestion);
1756 |   console.log('AI回复:', aiResponse);
1757 |   
1758 |   try {
1759 |     const activeConfig = config || getAIConfig();
1760 |     
1761 |     if (!activeConfig.apiKey || !activeConfig.endpoint) {
1762 |       console.warn('⚠️ 没有AI配置，使用模拟觉察分析');
1763 |       return mockAwarenessAnalysis(userQuestion, aiResponse);
1764 |     }
1765 |     
1766 |     console.log('🤖 使用AI进行觉察价值分析');
1767 |     return await callAIForAwarenessAnalysis(userQuestion, aiResponse, activeConfig);
1768 |     
1769 |   } catch (error) {
1770 |     console.warn('❌ 觉察分析失败，使用备用方案:', error);
1771 |     return mockAwarenessAnalysis(userQuestion, aiResponse);
1772 |   }
1773 | };
1774 | 
1775 | // AI觉察分析服务调用
1776 | const callAIForAwarenessAnalysis = async (
1777 |   userQuestion: string,
1778 |   aiResponse: string,
1779 |   config: AITaggingConfig
1780 | ): Promise<AwarenessInsight> => {
1781 |   const prompt = `
1782 | 你是一位专业的心理洞察分析师。请分析以下对话是否具有自我觉察的价值。
1783 | 
1784 | 用户问题: "${userQuestion}"
1785 | AI回答: "${aiResponse}"
1786 | 
1787 | 请判断这段对话是否帮助用户产生了自我觉察、情绪洞察或个人成长的洞见。
1788 | 
1789 | 觉察价值的判断标准：
1790 | 1. HIGH（高价值）：触及深层自我认知、价值观反思、行为模式认识、情绪根源探索
1791 | 2. MEDIUM（中等价值）：涉及个人情感、人际关系思考、生活态度调整
1792 | 3. LOW（低价值）：一般性建议、事实性信息、浅层交流
1793 | 4. NONE（无价值）：纯粹的信息咨询、技术问题、日常闲聊
1794 | 
1795 | 重要要求：后续问题必须以用户第一人称视角表达，像用户自己在思考和提问，而不是AI询问用户。
1796 | 
1797 | 例如：
1798 | - 错误："你觉得这种情绪是什么时候开始的？"
1799 | - 正确："我这种情绪是什么时候开始的呢？"
1800 | - 错误："你希望这种关系如何发展？"  
1801 | - 正确："我希望这种关系如何发展呢？"
1802 | 
1803 | 请严格按照以下JSON格式返回分析结果，不要添加任何其他文字：
1804 | 
1805 | {
1806 |   "hasInsight": <boolean: 是否有觉察价值>,
1807 |   "insightLevel": "<string: low/medium/high>",
1808 |   "insightType": "<string: 觉察类型，如'自我认知'、'情绪洞察'、'关系反思'等>",
1809 |   "keyInsights": ["<string: 关键洞察点1>", "<string: 关键洞察点2>"],
1810 |   "emotionalPattern": "<string: 识别到的情绪或行为模式>",
1811 |   "suggestedReflection": "<string: 建议的深入思考方向>",
1812 |   "followUpQuestions": ["<string: 用户第一人称后续探索问题1>", "<string: 用户第一人称后续探索问题2>"]
1813 | }
1814 | `;
1815 | 
1816 |   const requestBody = {
1817 |     model: config.model || 'gpt-3.5-turbo',
1818 |     messages: [{ role: 'user', content: prompt }],
1819 |     temperature: 0.3, // 较低温度确保一致性
1820 |     max_tokens: 2000,
1821 |     response_format: { type: "json_object" }
1822 |   };
1823 | 
1824 |   try {
1825 |     const cleanApiKey = config.apiKey?.replace(/[^\x20-\x7E]/g, '') || '';
1826 |     
1827 |     const response = await fetch(config.endpoint!, {
1828 |       method: 'POST',
1829 |       headers: {
1830 |         'Content-Type': 'application/json',
1831 |         'Authorization': `Bearer ${cleanApiKey}`,
1832 |       },
1833 |       body: JSON.stringify(requestBody),
1834 |     });
1835 | 
1836 |     if (!response.ok) {
1837 |       const errorText = await response.text();
1838 |       console.error(`觉察分析API错误 (${response.status}): ${errorText}`);
1839 |       throw new Error(`Awareness API error: ${response.status}`);
1840 |     }
1841 | 
1842 |     const data = await response.json();
1843 |     console.log('觉察分析原始响应:', JSON.stringify(data, null, 2));
1844 |     
1845 |     if (!data.choices || !data.choices[0] || !data.choices[0].message) {
1846 |       throw new Error('Invalid awareness analysis response structure');
1847 |     }
1848 | 
1849 |     const content = data.choices[0].message.content?.trim() || '';
1850 |     console.log('觉察分析内容:', content);
1851 |     
1852 |     // 解析JSON响应
1853 |     const cleanedContent = content
1854 |       .replace(/^```json\n?/, '')
1855 |       .replace(/\n?```$/, '')
1856 |       .trim();
1857 |     
1858 |     const parsedResult = JSON.parse(cleanedContent);
1859 |     
1860 |     // 验证必要字段
1861 |     if (typeof parsedResult.hasInsight !== 'boolean') {
1862 |       throw new Error('Invalid hasInsight field');
1863 |     }
1864 |     
1865 |     console.log('✅ 觉察分析完成:', parsedResult);
1866 |     return parsedResult as AwarenessInsight;
1867 |     
1868 |   } catch (error) {
1869 |     console.error('❌ AI觉察分析调用失败:', error);
1870 |     throw error;
1871 |   }
1872 | };
1873 | 
1874 | // 模拟觉察分析 - 备用方案
1875 | const mockAwarenessAnalysis = (userQuestion: string, aiResponse: string): AwarenessInsight => {
1876 |   const lowerQuestion = userQuestion.toLowerCase();
1877 |   const lowerResponse = aiResponse.toLowerCase();
1878 |   
1879 |   // 高觉察价值关键词
1880 |   const highInsightKeywords = [
1881 |     '为什么', '原因', '内心', '感受', '恐惧', '焦虑', '担心', '困惑', 
1882 |     '意义', '价值观', '目标', '梦想', '关系', '家庭', '自己', '成长',
1883 |     '改变', '选择', '决定', '未来', '过去', '痛苦', '快乐', '孤独',
1884 |     '自信', '自我', '认识', '理解', '接受', '原谅'
1885 |   ];
1886 |   
1887 |   // 中等觉察价值关键词  
1888 |   const mediumInsightKeywords = [
1889 |     '感觉', '想法', '看法', '态度', '习惯', '行为', '情绪', '心情',
1890 |     '压力', '疲惫', '兴奋', '满足', '失望', '希望', '期待', '担忧'
1891 |   ];
1892 |   
1893 |   // 统计关键词出现次数
1894 |   let highCount = 0;
1895 |   let mediumCount = 0;
1896 |   
1897 |   const combinedText = `${lowerQuestion} ${lowerResponse}`;
1898 |   
1899 |   highInsightKeywords.forEach(keyword => {
1900 |     if (combinedText.includes(keyword)) highCount++;
1901 |   });
1902 |   
1903 |   mediumInsightKeywords.forEach(keyword => {
1904 |     if (combinedText.includes(keyword)) mediumCount++;
1905 |   });
1906 |   
1907 |   // 判断觉察价值等级
1908 |   let insightLevel: 'low' | 'medium' | 'high' = 'low';
1909 |   let hasInsight = false;
1910 |   
1911 |   if (highCount >= 2) {
1912 |     insightLevel = 'high';
1913 |     hasInsight = true;
1914 |   } else if (highCount >= 1 || mediumCount >= 3) {
1915 |     insightLevel = 'medium';
1916 |     hasInsight = true;
1917 |   } else if (mediumCount >= 1) {
1918 |     insightLevel = 'low';
1919 |     hasInsight = true;
1920 |   }
1921 |   
1922 |   // 根据内容生成洞察类型和建议
1923 |   let insightType = '自我探索';
1924 |   let emotionalPattern = '思考模式';
1925 |   let suggestedReflection = '继续深入思考这个话题';
1926 |   let followUpQuestions = ['我对此还有什么其他想法？', '这让我想到了什么？'];
1927 |   
1928 |   if (combinedText.includes('感受') || combinedText.includes('情绪')) {
1929 |     insightType = '情绪洞察';
1930 |     emotionalPattern = '情绪觉察模式';
1931 |     suggestedReflection = '观察和理解自己的情绪反应';
1932 |     followUpQuestions = ['我这种情绪是什么时候开始的？', '在什么情况下我会有类似感受？'];
1933 |   }
1934 |   
1935 |   if (combinedText.includes('关系') || combinedText.includes('家庭') || combinedText.includes('朋友')) {
1936 |     insightType = '关系反思';
1937 |     emotionalPattern = '人际互动模式';
1938 |     suggestedReflection = '思考人际关系中的互动模式';
1939 |     followUpQuestions = ['在其他关系中我是否也有类似情况？', '我希望这种关系如何发展？'];
1940 |   }
1941 |   
1942 |   if (combinedText.includes('目标') || combinedText.includes('未来') || combinedText.includes('梦想')) {
1943 |     insightType = '人生规划';
1944 |     emotionalPattern = '目标导向思维';
1945 |     suggestedReflection = '明确自己真正想要的人生方向';
1946 |     followUpQuestions = ['什么阻碍了我实现这个目标？', '如果没有任何限制，我会如何规划？'];
1947 |   }
1948 |   
1949 |   const keyInsights = hasInsight ? [
1950 |     `识别到${insightType}的重要性`,
1951 |     '开始深入思考个人内在体验'
1952 |   ] : [];
1953 |   
1954 |   return {
1955 |     hasInsight,
1956 |     insightLevel,
1957 |     insightType,
1958 |     keyInsights,
1959 |     emotionalPattern,
1960 |     suggestedReflection,
1961 |     followUpQuestions
1962 |   };
1963 | };

```

`staroracle-app_allreact/src/utils/bookOfAnswers.ts`:

```ts
   1 | // Book of Answers utility
   2 | // This file contains the answers from the mystical "Book of Answers"
   3 | 
   4 | /**
   5 |  * The Book of Answers is a collection of mystical, thought-provoking responses
   6 |  * that provide guidance and reflection to unspoken questions.
   7 |  * Users mentally ask a question and receive one of these answers.
   8 |  */
   9 | 
  10 | export const getBookAnswer = (): string => {
  11 |   // Collection of answers inspired by "The Book of Answers" concept
  12 |   const answers = [
  13 |     "是的，毫无疑问。",
  14 |     "相信你的直觉。",
  15 |     "现在不是时候。",
  16 |     "宇宙已经安排好了。",
  17 |     "耐心等待，时机即将到来。",
  18 |     "不要强求，顺其自然。",
  19 |     "放手，让它去吧。",
  20 |     "是时候改变方向了。",
  21 |     "这个问题的答案就在你心中。",
  22 |     "寻求更多信息后再决定。",
  23 |     "绝对不要。",
  24 |     "现在就行动。",
  25 |     "接受它，然后前进。",
  26 |     "你已经知道答案了。",
  27 |     "这个决定将带来意想不到的结果。",
  28 |     "重新思考你的问题。",
  29 |     "寻求他人的建议。",
  30 |     "相信这个过程。",
  31 |     "答案将在梦中揭示。",
  32 |     "观察自然的征兆。",
  33 |     "是的，但不要操之过急。",
  34 |     "不，但不要放弃希望。",
  35 |     "暂时搁置这个问题。",
  36 |     "专注于当下。",
  37 |     "回顾过去的经验。",
  38 |     "这不是正确的问题。",
  39 |     "跟随你的心。",
  40 |     "这是一个转折点。",
  41 |     "答案就在你面前。",
  42 |     "勇敢地面对恐惧。",
  43 |     "等待更清晰的指引。",
  44 |     "信任这个旅程。",
  45 |     "接受不确定性。",
  46 |     "改变你的视角。",
  47 |     "这个问题需要更深入的思考。",
  48 |     "现在是行动的时候了。",
  49 |     "寻找平衡。",
  50 |     "放下过去。",
  51 |     "相信宇宙的时机。",
  52 |     "答案将在意想不到的地方出现。",
  53 |     "保持开放的心态。",
  54 |     "这个决定将影响你的未来道路。",
  55 |     "不要被表面现象迷惑。",
  56 |     "寻找内在的智慧。",
  57 |     "是的，如果你全心投入。",
  58 |     "不，除非情况发生变化。",
  59 |     "宇宙正在为你创造更好的机会。",
  60 |     "这个挑战是一份礼物。",
  61 |     "你比自己想象的更强大。",
  62 |     "答案在星光中闪烁。",
  63 |   ];
  64 |   
  65 |   // Return a random answer
  66 |   return answers[Math.floor(Math.random() * answers.length)];
  67 | };
  68 | 
  69 | // Get a more detailed, reflective follow-up to an answer
  70 | export const getAnswerReflection = (answer: string): string => {
  71 |   // Map of reflections for each answer type
  72 |   const reflections: Record<string, string[]> = {
  73 |     // Positive answers
  74 |     "是的，毫无疑问。": [
  75 |       "有时宇宙会给予明确的指引，这是一个清晰的信号。",
  76 |       "当道路如此清晰，勇敢前行是唯一的选择。",
  77 |       "确定性是一种礼物，珍视这一刻的清晰。"
  78 |     ],
  79 |     "相信你的直觉。": [
  80 |       "内在的声音往往比理性更能接近真相。",
  81 |       "直觉是灵魂的语言，它知道理性尚未发现的真理。",
  82 |       "最深刻的智慧常常以感觉的形式出现。"
  83 |     ],
  84 |     
  85 |     // Waiting answers
  86 |     "现在不是时候。": [
  87 |       "时机的重要性常被低估，耐心等待是一种智慧。",
  88 |       "有些种子需要更长的时间才能发芽，给它应有的时间。",
  89 |       "延迟并不意味着拒绝，只是宇宙的时间与我们的期望不同。"
  90 |     ],
  91 |     "耐心等待，时机即将到来。": [
  92 |       "等待的过程本身就是准备的一部分。",
  93 |       "即将到来的转变需要你完全准备好。",
  94 |       "黎明前的黑暗常常最为深沉。"
  95 |     ],
  96 |     
  97 |     // Default reflections for other answers
  98 |     "default": [
  99 |       "每个答案都是一面镜子，反射出提问者内心的真相。",
 100 |       "有时答案的价值不在于它的内容，而在于它引发的思考。",
 101 |       "智慧不在于获得确定的答案，而在于提出更好的问题。",
 102 |       "答案可能会随着时间的推移而揭示其更深层的含义。",
 103 |       "星辰的指引是微妙的，需要安静的心灵才能理解。"
 104 |     ]
 105 |   };
 106 |   
 107 |   // Get reflection for the specific answer or use default
 108 |   const specificReflections = reflections[answer] || reflections["default"];
 109 |   return specificReflections[Math.floor(Math.random() * specificReflections.length)];
 110 | }; 

```

`staroracle-app_allreact/src/utils/constellationTemplates.ts`:

```ts
   1 | import { ConstellationTemplate, Star, Connection } from '../types';
   2 | 
   3 | // 辅助函数，将旧的emotionalTone转换为新的格式
   4 | const convertOldEmotionalTone = (oldTone: string): string => {
   5 |   const mapping: Record<string, string> = {
   6 |     'positive': '充满希望的',
   7 |     'contemplative': '思考的',
   8 |     'seeking': '探寻中',
   9 |     'neutral': '中性的'
  10 |   };
  11 |   return mapping[oldTone] || '探寻中';
  12 | };
  13 | 
  14 | // 辅助函数，将旧的category转换为新的primary_category
  15 | const convertOldCategory = (oldCategory: string): string => {
  16 |   const mapping: Record<string, string> = {
  17 |     'relationships': 'relationships',
  18 |     'personal_growth': 'personal_growth',
  19 |     'life_direction': 'career_and_purpose',
  20 |     'wellbeing': 'emotional_wellbeing',
  21 |     'material': 'daily_life',
  22 |     'creative': 'creativity_and_passion',
  23 |     'existential': 'philosophy_and_existence'
  24 |   };
  25 |   return mapping[oldCategory] || 'philosophy_and_existence';
  26 | };
  27 | 
  28 | // 根据问题文本推断问题类型
  29 | const getQuestionType = (question: string): string => {
  30 |   const lowerQuestion = question.toLowerCase();
  31 |   if (lowerQuestion.includes('为什么') || lowerQuestion.includes('why') || 
  32 |       lowerQuestion.includes('是否') || lowerQuestion.includes('if') || 
  33 |       lowerQuestion.includes('是不是')) {
  34 |     return '探索型';
  35 |   } else if (lowerQuestion.includes('如何') || lowerQuestion.includes('how to') || 
  36 |              lowerQuestion.includes('方法') || lowerQuestion.includes('steps')) {
  37 |     return '实用型';
  38 |   } else if (lowerQuestion.includes('什么是') || lowerQuestion.includes('what is') || 
  39 |              lowerQuestion.includes('谁') || lowerQuestion.includes('who') || 
  40 |              lowerQuestion.includes('where')) {
  41 |     return '事实型';
  42 |   }
  43 |   // 默认返回探索型
  44 |   return '探索型';
  45 | };
  46 | 
  47 | // 根据类别生成默认的追问
  48 | const getSuggestedFollowUp = (category: string): string => {
  49 |   const followUpMap: Record<string, string> = {
  50 |     'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
  51 |     'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
  52 |     'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
  53 |     'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
  54 |     'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
  55 |     'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
  56 |     'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
  57 |   };
  58 |   return followUpMap[category] || '关于这个话题，你还有什么更深层次的感受或想法？';
  59 | };
  60 | 
  61 | // 12星座模板数据
  62 | export const ZODIAC_TEMPLATES: ConstellationTemplate[] = [
  63 |   {
  64 |     id: 'aries',
  65 |     name: 'Aries',
  66 |     chineseName: '白羊座',
  67 |     description: '勇敢的开拓者，充满激情与活力',
  68 |     element: 'fire',
  69 |     centerX: 25,
  70 |     centerY: 30,
  71 |     scale: 1.0,
  72 |     stars: [
  73 |       {
  74 |         id: 'aries-1',
  75 |         x: 0,
  76 |         y: 0,
  77 |         size: 4,
  78 |         brightness: 1.0,
  79 |         question: '我如何发现自己的勇气？',
  80 |         answer: '勇气如火星般燃烧，在行动中点燃，在挑战中壮大。',
  81 |         tags: ['courage', 'leadership', 'action', 'passion', 'initiative'],
  82 |         category: 'personal_growth',
  83 |         emotionalTone: 'positive',
  84 |         isMainStar: true
  85 |       },
  86 |       {
  87 |         id: 'aries-2',
  88 |         x: -8,
  89 |         y: 5,
  90 |         size: 3,
  91 |         brightness: 0.8,
  92 |         question: '如何成为更好的领导者？',
  93 |         answer: '真正的领导者如北极星，不是最亮的，却为他人指引方向。',
  94 |         tags: ['leadership', 'guidance', 'responsibility', 'vision'],
  95 |         category: 'life_direction',
  96 |         emotionalTone: 'contemplative'
  97 |       },
  98 |       {
  99 |         id: 'aries-3',
 100 |         x: 8,
 101 |         y: -3,
 102 |         size: 2.5,
 103 |         brightness: 0.7,
 104 |         question: '我的激情在哪里？',
 105 |         answer: '激情如恒星核心的聚变，从内心深处释放无穷能量。',
 106 |         tags: ['passion', 'energy', 'motivation', 'drive'],
 107 |         category: 'personal_growth',
 108 |         emotionalTone: 'seeking'
 109 |       },
 110 |       {
 111 |         id: 'aries-4',
 112 |         x: 3,
 113 |         y: 8,
 114 |         size: 2,
 115 |         brightness: 0.6,
 116 |         question: '如何开始新的征程？',
 117 |         answer: '每个新开始都是宇宙的重新创造，勇敢迈出第一步。',
 118 |         tags: ['new_beginnings', 'adventure', 'courage', 'change'],
 119 |         category: 'life_direction',
 120 |         emotionalTone: 'positive'
 121 |       }
 122 |     ],
 123 |     connections: [
 124 |       { fromStarId: 'aries-1', toStarId: 'aries-2', strength: 0.8, sharedTags: ['leadership', 'courage'] },
 125 |       { fromStarId: 'aries-1', toStarId: 'aries-3', strength: 0.7, sharedTags: ['passion', 'energy'] },
 126 |       { fromStarId: 'aries-2', toStarId: 'aries-4', strength: 0.6, sharedTags: ['leadership', 'new_beginnings'] }
 127 |     ]
 128 |   },
 129 |   {
 130 |     id: 'taurus',
 131 |     name: 'Taurus',
 132 |     chineseName: '金牛座',
 133 |     description: '稳重的建设者，追求美好与安全',
 134 |     element: 'earth',
 135 |     centerX: 75,
 136 |     centerY: 25,
 137 |     scale: 1.0,
 138 |     stars: [
 139 |       {
 140 |         id: 'taurus-1',
 141 |         x: 0,
 142 |         y: 0,
 143 |         size: 4,
 144 |         brightness: 1.0,
 145 |         question: '如何建立稳定的生活？',
 146 |         answer: '稳定如大地般深厚，在耐心与坚持中慢慢积累。',
 147 |         tags: ['stability', 'security', 'patience', 'persistence'],
 148 |         category: 'wellbeing',
 149 |         emotionalTone: 'contemplative',
 150 |         isMainStar: true
 151 |       },
 152 |       {
 153 |         id: 'taurus-2',
 154 |         x: -6,
 155 |         y: -4,
 156 |         size: 3,
 157 |         brightness: 0.8,
 158 |         question: '什么是真正的财富？',
 159 |         answer: '真正的财富不在金库，而在心灵的富足与关系的深度。',
 160 |         tags: ['wealth', 'abundance', 'values', 'material'],
 161 |         category: 'material',
 162 |         emotionalTone: 'contemplative'
 163 |       },
 164 |       {
 165 |         id: 'taurus-3',
 166 |         x: 7,
 167 |         y: 6,
 168 |         size: 2.5,
 169 |         brightness: 0.7,
 170 |         question: '如何欣赏生活中的美？',
 171 |         answer: '美如花朵在感恩的土壤中绽放，用心感受每个瞬间。',
 172 |         tags: ['beauty', 'appreciation', 'senses', 'gratitude'],
 173 |         category: 'wellbeing',
 174 |         emotionalTone: 'positive'
 175 |       },
 176 |       {
 177 |         id: 'taurus-4',
 178 |         x: 2,
 179 |         y: -8,
 180 |         size: 2,
 181 |         brightness: 0.6,
 182 |         question: '如何保持内心的平静？',
 183 |         answer: '平静如深山古井，不因外界波动而失去内在的宁静。',
 184 |         tags: ['peace', 'calm', 'stability', 'inner_strength'],
 185 |         category: 'wellbeing',
 186 |         emotionalTone: 'contemplative'
 187 |       }
 188 |     ],
 189 |     connections: [
 190 |       { fromStarId: 'taurus-1', toStarId: 'taurus-2', strength: 0.7, sharedTags: ['stability', 'security'] },
 191 |       { fromStarId: 'taurus-1', toStarId: 'taurus-4', strength: 0.8, sharedTags: ['stability', 'peace'] },
 192 |       { fromStarId: 'taurus-3', toStarId: 'taurus-4', strength: 0.6, sharedTags: ['peace', 'appreciation'] }
 193 |     ]
 194 |   },
 195 |   {
 196 |     id: 'gemini',
 197 |     name: 'Gemini',
 198 |     chineseName: '双子座',
 199 |     description: '好奇的探索者，善于沟通与学习',
 200 |     element: 'air',
 201 |     centerX: 50,
 202 |     centerY: 70,
 203 |     scale: 1.0,
 204 |     stars: [
 205 |       {
 206 |         id: 'gemini-1',
 207 |         x: -4,
 208 |         y: 0,
 209 |         size: 3.5,
 210 |         brightness: 0.9,
 211 |         question: '如何提升我的沟通能力？',
 212 |         answer: '沟通如双星系统，倾听与表达相互环绕，创造和谐共鸣。',
 213 |         tags: ['communication', 'expression', 'listening', 'connection'],
 214 |         category: 'relationships',
 215 |         emotionalTone: 'seeking',
 216 |         isMainStar: true
 217 |       },
 218 |       {
 219 |         id: 'gemini-2',
 220 |         x: 4,
 221 |         y: 0,
 222 |         size: 3.5,
 223 |         brightness: 0.9,
 224 |         question: '如何平衡生活的多面性？',
 225 |         answer: '如月亮的阴晴圆缺，拥抱你内在的多重面向，它们都是完整的你。',
 226 |         tags: ['balance', 'duality', 'adaptability', 'flexibility'],
 227 |         category: 'personal_growth',
 228 |         emotionalTone: 'contemplative',
 229 |         isMainStar: true
 230 |       },
 231 |       {
 232 |         id: 'gemini-3',
 233 |         x: 0,
 234 |         y: -6,
 235 |         size: 2.5,
 236 |         brightness: 0.7,
 237 |         question: '如何保持学习的热情？',
 238 |         answer: '好奇心如星际尘埃，在宇宙中永远飘散，永远发现新的世界。',
 239 |         tags: ['learning', 'curiosity', 'knowledge', 'growth'],
 240 |         category: 'personal_growth',
 241 |         emotionalTone: 'positive'
 242 |       },
 243 |       {
 244 |         id: 'gemini-4',
 245 |         x: 0,
 246 |         y: 6,
 247 |         size: 2,
 248 |         brightness: 0.6,
 249 |         question: '如何建立深度的友谊？',
 250 |         answer: '友谊如星座，看似分散的点，实则由无形的引力紧密相连。',
 251 |         tags: ['friendship', 'connection', 'loyalty', 'understanding'],
 252 |         category: 'relationships',
 253 |         emotionalTone: 'positive'
 254 |       }
 255 |     ],
 256 |     connections: [
 257 |       { fromStarId: 'gemini-1', toStarId: 'gemini-2', strength: 0.9, sharedTags: ['communication', 'balance'] },
 258 |       { fromStarId: 'gemini-1', toStarId: 'gemini-4', strength: 0.7, sharedTags: ['communication', 'connection'] },
 259 |       { fromStarId: 'gemini-2', toStarId: 'gemini-3', strength: 0.6, sharedTags: ['growth', 'adaptability'] }
 260 |     ]
 261 |   },
 262 |   {
 263 |     id: 'cancer',
 264 |     name: 'Cancer',
 265 |     chineseName: '巨蟹座',
 266 |     description: '温暖的守护者，重视家庭与情感',
 267 |     element: 'water',
 268 |     centerX: 20,
 269 |     centerY: 75,
 270 |     scale: 1.0,
 271 |     stars: [
 272 |       {
 273 |         id: 'cancer-1',
 274 |         x: 0,
 275 |         y: 0,
 276 |         size: 4,
 277 |         brightness: 1.0,
 278 |         question: '如何创造温暖的家？',
 279 |         answer: '家不在建筑中，而在心灵的港湾，用爱编织的安全感。',
 280 |         tags: ['home', 'family', 'security', 'nurturing', 'love'],
 281 |         category: 'relationships',
 282 |         emotionalTone: 'positive',
 283 |         isMainStar: true
 284 |       },
 285 |       {
 286 |         id: 'cancer-2',
 287 |         x: -5,
 288 |         y: 5,
 289 |         size: 3,
 290 |         brightness: 0.8,
 291 |         question: '如何处理敏感的情感？',
 292 |         answer: '敏感如月光映水，既是脆弱也是力量，学会拥抱你的深度。',
 293 |         tags: ['emotions', 'sensitivity', 'intuition', 'empathy'],
 294 |         category: 'personal_growth',
 295 |         emotionalTone: 'contemplative'
 296 |       },
 297 |       {
 298 |         id: 'cancer-3',
 299 |         x: 6,
 300 |         y: -3,
 301 |         size: 2.5,
 302 |         brightness: 0.7,
 303 |         question: '如何照顾他人又不失自我？',
 304 |         answer: '如月亮照亮夜空却不失去自己的光芒，给予中保持自我的完整。',
 305 |         tags: ['caring', 'boundaries', 'self_care', 'balance'],
 306 |         category: 'relationships',
 307 |         emotionalTone: 'seeking'
 308 |       },
 309 |       {
 310 |         id: 'cancer-4',
 311 |         x: 2,
 312 |         y: 7,
 313 |         size: 2,
 314 |         brightness: 0.6,
 315 |         question: '如何找到内心的安全感？',
 316 |         answer: '真正的安全感来自内心的根基，如深海般宁静而深邃。',
 317 |         tags: ['security', 'inner_peace', 'self_trust', 'stability'],
 318 |         category: 'wellbeing',
 319 |         emotionalTone: 'contemplative'
 320 |       }
 321 |     ],
 322 |     connections: [
 323 |       { fromStarId: 'cancer-1', toStarId: 'cancer-2', strength: 0.8, sharedTags: ['emotions', 'nurturing'] },
 324 |       { fromStarId: 'cancer-1', toStarId: 'cancer-4', strength: 0.7, sharedTags: ['security', 'home'] },
 325 |       { fromStarId: 'cancer-2', toStarId: 'cancer-3', strength: 0.6, sharedTags: ['emotions', 'caring'] }
 326 |     ]
 327 |   },
 328 |   {
 329 |     id: 'leo',
 330 |     name: 'Leo',
 331 |     chineseName: '狮子座',
 332 |     description: '自信的表演者，散发光芒与魅力',
 333 |     element: 'fire',
 334 |     centerX: 80,
 335 |     centerY: 60,
 336 |     scale: 1.0,
 337 |     stars: [
 338 |       {
 339 |         id: 'leo-1',
 340 |         x: 0,
 341 |         y: 0,
 342 |         size: 4.5,
 343 |         brightness: 1.0,
 344 |         question: '如何建立真正的自信？',
 345 |         answer: '自信如太阳般从内心发光，不需要外界的认可来证明自己的价值。',
 346 |         tags: ['confidence', 'self_worth', 'authenticity', 'inner_strength'],
 347 |         category: 'personal_growth',
 348 |         emotionalTone: 'positive',
 349 |         isMainStar: true
 350 |       },
 351 |       {
 352 |         id: 'leo-2',
 353 |         x: -6,
 354 |         y: -4,
 355 |         size: 3,
 356 |         brightness: 0.8,
 357 |         question: '如何展现我的创造力？',
 358 |         answer: '创造力如恒星的光芒，需要勇气点燃，用热情维持燃烧。',
 359 |         tags: ['creativity', 'expression', 'art', 'passion', 'uniqueness'],
 360 |         category: 'creative',
 361 |         emotionalTone: 'positive'
 362 |       },
 363 |       {
 364 |         id: 'leo-3',
 365 |         x: 7,
 366 |         y: 5,
 367 |         size: 2.5,
 368 |         brightness: 0.7,
 369 |         question: '如何成为他人的光芒？',
 370 |         answer: '如太阳照亮行星，真正的光芒在于启发他人发现自己的光。',
 371 |         tags: ['inspiration', 'leadership', 'generosity', 'influence'],
 372 |         category: 'relationships',
 373 |         emotionalTone: 'positive'
 374 |       },
 375 |       {
 376 |         id: 'leo-4',
 377 |         x: 3,
 378 |         y: -7,
 379 |         size: 2,
 380 |         brightness: 0.6,
 381 |         question: '如何平衡自我与谦逊？',
 382 |         answer: '真正的王者如太阳，强大而温暖，照亮一切却不炫耀自己。',
 383 |         tags: ['humility', 'balance', 'wisdom', 'maturity'],
 384 |         category: 'personal_growth',
 385 |         emotionalTone: 'contemplative'
 386 |       }
 387 |     ],
 388 |     connections: [
 389 |       { fromStarId: 'leo-1', toStarId: 'leo-2', strength: 0.8, sharedTags: ['confidence', 'creativity'] },
 390 |       { fromStarId: 'leo-1', toStarId: 'leo-3', strength: 0.7, sharedTags: ['confidence', 'leadership'] },
 391 |       { fromStarId: 'leo-2', toStarId: 'leo-3', strength: 0.6, sharedTags: ['creativity', 'inspiration'] }
 392 |     ]
 393 |   },
 394 |   {
 395 |     id: 'virgo',
 396 |     name: 'Virgo',
 397 |     chineseName: '处女座',
 398 |     description: '完美的工匠，追求精确与服务',
 399 |     element: 'earth',
 400 |     centerX: 30,
 401 |     centerY: 50,
 402 |     scale: 1.0,
 403 |     stars: [
 404 |       {
 405 |         id: 'virgo-1',
 406 |         x: 0,
 407 |         y: 0,
 408 |         size: 4,
 409 |         brightness: 1.0,
 410 |         question: '如何在细节中找到完美？',
 411 |         answer: '完美不在无瑕，而在每个细节中倾注的爱与专注。',
 412 |         tags: ['perfection', 'attention', 'craftsmanship', 'dedication'],
 413 |         category: 'personal_growth',
 414 |         emotionalTone: 'contemplative',
 415 |         isMainStar: true
 416 |       },
 417 |       {
 418 |         id: 'virgo-2',
 419 |         x: -5,
 420 |         y: 6,
 421 |         size: 3,
 422 |         brightness: 0.8,
 423 |         question: '如何更好地服务他人？',
 424 |         answer: '服务如星光，看似微小却能照亮他人前行的道路。',
 425 |         tags: ['service', 'helping', 'contribution', 'purpose'],
 426 |         category: 'relationships',
 427 |         emotionalTone: 'positive'
 428 |       },
 429 |       {
 430 |         id: 'virgo-3',
 431 |         x: 6,
 432 |         y: -4,
 433 |         size: 2.5,
 434 |         brightness: 0.7,
 435 |         question: '如何管理我的时间和精力？',
 436 |         answer: '时间如星辰运行，有序而精确，在规律中找到效率的美。',
 437 |         tags: ['organization', 'efficiency', 'planning', 'discipline'],
 438 |         category: 'life_direction',
 439 |         emotionalTone: 'seeking'
 440 |       },
 441 |       {
 442 |         id: 'virgo-4',
 443 |         x: 2,
 444 |         y: 8,
 445 |         size: 2,
 446 |         brightness: 0.6,
 447 |         question: '如何接受不完美的自己？',
 448 |         answer: '如星空中的每颗星都有独特的光芒，不完美也是美的一种形式。',
 449 |         tags: ['self_acceptance', 'growth', 'compassion', 'healing'],
 450 |         category: 'personal_growth',
 451 |         emotionalTone: 'contemplative'
 452 |       }
 453 |     ],
 454 |     connections: [
 455 |       { fromStarId: 'virgo-1', toStarId: 'virgo-3', strength: 0.8, sharedTags: ['perfection', 'organization'] },
 456 |       { fromStarId: 'virgo-1', toStarId: 'virgo-4', strength: 0.7, sharedTags: ['perfection', 'growth'] },
 457 |       { fromStarId: 'virgo-2', toStarId: 'virgo-4', strength: 0.6, sharedTags: ['service', 'compassion'] }
 458 |     ]
 459 |   }
 460 |   // 可以继续添加其他6个星座...
 461 | ];
 462 | 
 463 | // 获取所有星座模板
 464 | export const getAllTemplates = (): ConstellationTemplate[] => {
 465 |   return ZODIAC_TEMPLATES;
 466 | };
 467 | 
 468 | // 根据ID获取特定星座模板
 469 | export const getTemplateById = (id: string): ConstellationTemplate | undefined => {
 470 |   return ZODIAC_TEMPLATES.find(template => template.id === id);
 471 | };
 472 | 
 473 | // 根据元素获取星座模板
 474 | export const getTemplatesByElement = (element: 'fire' | 'earth' | 'air' | 'water'): ConstellationTemplate[] => {
 475 |   return ZODIAC_TEMPLATES.filter(template => template.element === element);
 476 | };
 477 | 
 478 | // 将模板转换为实际的星星和连接
 479 | export const instantiateTemplate = (template: ConstellationTemplate, offsetX: number = 0, offsetY: number = 0) => {
 480 |   const stars = template.stars.map(starData => {
 481 |     // 将旧的category和emotionalTone字段转换为新的字段格式
 482 |     const emotional_tone = Array.isArray(starData.emotional_tone) ? 
 483 |       starData.emotional_tone : 
 484 |       [convertOldEmotionalTone(starData.emotionalTone)];
 485 | 
 486 |     // 转换旧的类别字段
 487 |     const primary_category = starData.primary_category || 
 488 |                        convertOldCategory(starData.category as string);
 489 |     
 490 |     // 创建新的星星对象
 491 |     return {
 492 |       id: `${template.id}-${starData.id}-${Date.now()}`,
 493 |       x: template.centerX + (starData.x * template.scale) + offsetX,
 494 |       y: template.centerY + (starData.y * template.scale) + offsetY,
 495 |       size: starData.size,
 496 |       brightness: starData.brightness,
 497 |       question: starData.question,
 498 |       answer: starData.answer,
 499 |       imageUrl: `https://images.pexels.com/photos/${Math.floor(Math.random() * 2000000) + 1000000}/pexels-photo-${Math.floor(Math.random() * 2000000) + 1000000}.jpeg`,
 500 |       createdAt: new Date(),
 501 |       isSpecial: starData.isMainStar || false,
 502 |       tags: starData.tags,
 503 |       primary_category: primary_category,
 504 |       emotional_tone: emotional_tone,
 505 |       question_type: starData.question_type || getQuestionType(starData.question),
 506 |       insight_level: starData.insight_level || {
 507 |         value: starData.isMainStar ? 4 : 3,
 508 |         description: starData.isMainStar ? '启明星' : '寻常星'
 509 |       },
 510 |       initial_luminosity: starData.initial_luminosity || (starData.isMainStar ? 90 : 60),
 511 |       connection_potential: starData.connection_potential || 4,
 512 |       suggested_follow_up: starData.suggested_follow_up || getSuggestedFollowUp(primary_category),
 513 |       card_summary: starData.card_summary || starData.question,
 514 |       isTemplate: true,
 515 |       templateType: template.chineseName
 516 |     };
 517 |   });
 518 | 
 519 |   const connections: Connection[] = [];
 520 |   
 521 |   // Create connections, filtering out null values
 522 |   template.connections.forEach(connData => {
 523 |     const fromStar = stars.find(s => s.id.includes(connData.fromStarId));
 524 |     const toStar = stars.find(s => s.id.includes(connData.toStarId));
 525 |     
 526 |     if (fromStar && toStar) {
 527 |       connections.push({
 528 |         id: `connection-${fromStar.id}-${toStar.id}`,
 529 |         fromStarId: fromStar.id,
 530 |         toStarId: toStar.id,
 531 |         strength: connData.strength,
 532 |         sharedTags: connData.sharedTags,
 533 |         isTemplate: true
 534 |       });
 535 |     }
 536 |   });
 537 | 
 538 |   return { stars, connections };
 539 | };

```

`staroracle-app_allreact/src/utils/hapticUtils.ts`:

```ts
   1 | import { Capacitor } from '@capacitor/core';
   2 | import { Haptics, ImpactStyle } from '@capacitor/haptics';
   3 | 
   4 | export const triggerHapticFeedback = async (type: 'light' | 'medium' | 'heavy' | 'success' | 'warning' | 'error' = 'light') => {
   5 |   if (!Capacitor.isNativePlatform()) return;
   6 |   
   7 |   try {
   8 |     switch (type) {
   9 |       case 'light':
  10 |         await Haptics.impact({ style: ImpactStyle.Light });
  11 |         break;
  12 |       case 'medium':
  13 |         await Haptics.impact({ style: ImpactStyle.Medium });
  14 |         break;
  15 |       case 'heavy':
  16 |         await Haptics.impact({ style: ImpactStyle.Heavy });
  17 |         break;
  18 |       case 'success':
  19 |       case 'warning':
  20 |       case 'error':
  21 |         // 对于通知类型，使用中等强度的冲击反馈
  22 |         await Haptics.impact({ style: ImpactStyle.Medium });
  23 |         break;
  24 |     }
  25 |   } catch (error) {
  26 |     console.warn('Haptic feedback not available:', error);
  27 |   }
  28 | };
  29 | 
  30 | export const triggerSelectionHaptic = async () => {
  31 |   if (!Capacitor.isNativePlatform()) return;
  32 |   
  33 |   try {
  34 |     await Haptics.selectionStart();
  35 |     setTimeout(async () => {
  36 |       await Haptics.selectionEnd();
  37 |     }, 100);
  38 |   } catch (error) {
  39 |     console.warn('Selection haptic not available:', error);
  40 |   }
  41 | };

```

`staroracle-app_allreact/src/utils/imageUtils.ts`:

```ts
   1 | // This function simulates generating a unique cosmic image for each star
   2 | // In a real app, this would connect to an AI image generation service
   3 | export const generateRandomStarImage = (): string => {
   4 |   // Array of cosmic-themed images from Pexels
   5 |   const cosmicImages = [
   6 |     'https://images.pexels.com/photos/1169754/pexels-photo-1169754.jpeg',
   7 |     'https://images.pexels.com/photos/1252890/pexels-photo-1252890.jpeg',
   8 |     'https://images.pexels.com/photos/1274260/pexels-photo-1274260.jpeg',
   9 |     'https://images.pexels.com/photos/1694000/pexels-photo-1694000.jpeg',
  10 |     'https://images.pexels.com/photos/1257860/pexels-photo-1257860.jpeg',
  11 |     'https://images.pexels.com/photos/1906658/pexels-photo-1906658.jpeg',
  12 |     'https://images.pexels.com/photos/1146134/pexels-photo-1146134.jpeg',
  13 |     'https://images.pexels.com/photos/1341279/pexels-photo-1341279.jpeg',
  14 |     'https://images.pexels.com/photos/816608/pexels-photo-816608.jpeg',
  15 |     'https://images.pexels.com/photos/1434608/pexels-photo-1434608.jpeg',
  16 |     'https://images.pexels.com/photos/1938348/pexels-photo-1938348.jpeg',
  17 |     'https://images.pexels.com/photos/1693095/pexels-photo-1693095.jpeg',
  18 |   ];
  19 |   
  20 |   // Return a random image from the array
  21 |   return cosmicImages[Math.floor(Math.random() * cosmicImages.length)];
  22 | };

```

`staroracle-app_allreact/src/utils/inspirationCards.ts`:

```ts
   1 | // 灵感卡片系统
   2 | export interface InspirationCard {
   3 |   id: string;
   4 |   question: string;
   5 |   reflection: string;
   6 |   tags: string[];
   7 |   category: string;
   8 |   emotionalTone: 'positive' | 'neutral' | 'contemplative' | 'seeking';
   9 | }
  10 | 
  11 | // 灵感卡片数据库
  12 | const INSPIRATION_CARDS: InspirationCard[] = [
  13 |   // 自我探索类
  14 |   {
  15 |     id: 'self-1',
  16 |     question: '如果今天是你生命的最后一天，你最想做什么？',
  17 |     reflection: '生命的有限性让每个选择都变得珍贵，真正重要的事物会在这种思考中浮现。',
  18 |     tags: ['life', 'priorities', 'meaning', 'death', 'values'],
  19 |     category: 'existential',
  20 |     emotionalTone: 'contemplative'
  21 |   },
  22 |   {
  23 |     id: 'self-2',
  24 |     question: '你最害怕失去的是什么？为什么？',
  25 |     reflection: '恐惧往往指向我们最珍视的东西，了解恐惧就是了解自己的价值观。',
  26 |     tags: ['fear', 'loss', 'values', 'attachment', 'security'],
  27 |     category: 'personal_growth',
  28 |     emotionalTone: 'seeking'
  29 |   },
  30 |   {
  31 |     id: 'self-3',
  32 |     question: '如果你可以给10年前的自己一个建议，会是什么？',
  33 |     reflection: '回望过去的智慧往往是对当下最好的指引。',
  34 |     tags: ['wisdom', 'growth', 'regret', 'learning', 'time'],
  35 |     category: 'personal_growth',
  36 |     emotionalTone: 'contemplative'
  37 |   },
  38 |   {
  39 |     id: 'self-4',
  40 |     question: '什么时候你感到最像真正的自己？',
  41 |     reflection: '真实的自我在特定的时刻和环境中会自然流露，找到这些时刻就是找到回家的路。',
  42 |     tags: ['authenticity', 'self', 'identity', 'freedom', 'truth'],
  43 |     category: 'personal_growth',
  44 |     emotionalTone: 'seeking'
  45 |   },
  46 | 
  47 |   // 关系类
  48 |   {
  49 |     id: 'relationship-1',
  50 |     question: '你在关系中最容易重复的模式是什么？',
  51 |     reflection: '我们在关系中的模式往往反映了内心深处的信念和恐惧。',
  52 |     tags: ['relationships', 'patterns', 'behavior', 'awareness', 'growth'],
  53 |     category: 'relationships',
  54 |     emotionalTone: 'contemplative'
  55 |   },
  56 |   {
  57 |     id: 'relationship-2',
  58 |     question: '如果你的朋友用三个词形容你，会是哪三个词？',
  59 |     reflection: '他人眼中的我们往往能揭示我们自己看不到的特质。',
  60 |     tags: ['identity', 'perception', 'friendship', 'self_image', 'reflection'],
  61 |     category: 'relationships',
  62 |     emotionalTone: 'seeking'
  63 |   },
  64 |   {
  65 |     id: 'relationship-3',
  66 |     question: '你最想对某个人说但一直没说的话是什么？',
  67 |     reflection: '未说出的话语往往承载着我们最深的情感和遗憾。',
  68 |     tags: ['communication', 'regret', 'courage', 'expression', 'love'],
  69 |     category: 'relationships',
  70 |     emotionalTone: 'contemplative'
  71 |   },
  72 | 
  73 |   // 梦想与目标类
  74 |   {
  75 |     id: 'dreams-1',
  76 |     question: '如果金钱不是问题，你会如何度过你的一生？',
  77 |     reflection: '当外在限制被移除，内心真正的渴望就会显现。',
  78 |     tags: ['dreams', 'freedom', 'purpose', 'passion', 'life_design'],
  79 |     category: 'life_direction',
  80 |     emotionalTone: 'positive'
  81 |   },
  82 |   {
  83 |     id: 'dreams-2',
  84 |     question: '你小时候的梦想现在还重要吗？为什么？',
  85 |     reflection: '童年的梦想往往包含着我们最纯真的渴望，值得重新审视。',
  86 |     tags: ['childhood', 'dreams', 'growth', 'change', 'authenticity'],
  87 |     category: 'life_direction',
  88 |     emotionalTone: 'contemplative'
  89 |   },
  90 |   {
  91 |     id: 'dreams-3',
  92 |     question: '什么阻止了你追求真正想要的生活？',
  93 |     reflection: '障碍往往不在外界，而在我们内心的信念和恐惧中。',
  94 |     tags: ['obstacles', 'fear', 'limiting_beliefs', 'courage', 'change'],
  95 |     category: 'life_direction',
  96 |     emotionalTone: 'seeking'
  97 |   },
  98 | 
  99 |   // 情感与内心类
 100 |   {
 101 |     id: 'emotion-1',
 102 |     question: '你最近一次真正快乐是什么时候？那种感觉是什么样的？',
 103 |     reflection: '快乐的记忆是心灵的指南针，指向我们真正需要的方向。',
 104 |     tags: ['happiness', 'joy', 'memory', 'fulfillment', 'gratitude'],
 105 |     category: 'wellbeing',
 106 |     emotionalTone: 'positive'
 107 |   },
 108 |   {
 109 |     id: 'emotion-2',
 110 |     question: '如果你的情绪是一种天气，现在是什么天气？',
 111 |     reflection: '用自然的语言描述情绪，往往能带来更深的理解和接纳。',
 112 |     tags: ['emotions', 'metaphor', 'awareness', 'feelings', 'weather'],
 113 |     category: 'wellbeing',
 114 |     emotionalTone: 'contemplative'
 115 |   },
 116 |   {
 117 |     id: 'emotion-3',
 118 |     question: '你最想治愈内心的哪个部分？',
 119 |     reflection: '承认伤痛是治愈的第一步，每个伤口都包含着成长的种子。',
 120 |     tags: ['healing', 'pain', 'growth', 'self_care', 'compassion'],
 121 |     category: 'wellbeing',
 122 |     emotionalTone: 'seeking'
 123 |   },
 124 | 
 125 |   // 创造与表达类
 126 |   {
 127 |     id: 'creative-1',
 128 |     question: '如果你必须创造一件作品来代表现在的你，会是什么？',
 129 |     reflection: '创造是自我表达的最直接方式，作品往往比言语更能传达内心。',
 130 |     tags: ['creativity', 'expression', 'art', 'identity', 'representation'],
 131 |     category: 'creative',
 132 |     emotionalTone: 'positive'
 133 |   },
 134 |   {
 135 |     id: 'creative-2',
 136 |     question: '你最想学会的技能是什么？为什么？',
 137 |     reflection: '我们渴望学习的技能往往反映了内心未被满足的表达需求。',
 138 |     tags: ['learning', 'skills', 'growth', 'curiosity', 'development'],
 139 |     category: 'creative',
 140 |     emotionalTone: 'seeking'
 141 |   },
 142 | 
 143 |   // 哲学与存在类
 144 |   {
 145 |     id: 'philosophy-1',
 146 |     question: '如果你可以知道一个关于宇宙的终极真理，你想知道什么？',
 147 |     reflection: '我们对终极真理的好奇往往反映了当下最困扰我们的问题。',
 148 |     tags: ['truth', 'universe', 'meaning', 'curiosity', 'existence'],
 149 |     category: 'existential',
 150 |     emotionalTone: 'contemplative'
 151 |   },
 152 |   {
 153 |     id: 'philosophy-2',
 154 |     question: '什么让你感到生命是有意义的？',
 155 |     reflection: '意义不是被发现的，而是被创造的，在我们的选择和行动中诞生。',
 156 |     tags: ['meaning', 'purpose', 'life', 'significance', 'values'],
 157 |     category: 'existential',
 158 |     emotionalTone: 'contemplative'
 159 |   },
 160 |   {
 161 |     id: 'philosophy-3',
 162 |     question: '如果今天是世界的最后一天，你会如何度过？',
 163 |     reflection: '末日的假设能够剥离一切不重要的东西，让真正珍贵的浮现。',
 164 |     tags: ['priorities', 'death', 'meaning', 'love', 'presence'],
 165 |     category: 'existential',
 166 |     emotionalTone: 'contemplative'
 167 |   },
 168 | 
 169 |   // 成长与变化类
 170 |   {
 171 |     id: 'growth-1',
 172 |     question: '你最想改变自己的哪个方面？为什么？',
 173 |     reflection: '改变的渴望往往指向我们对更好自己的向往，也反映了当下的不满足。',
 174 |     tags: ['change', 'growth', 'improvement', 'self_development', 'aspiration'],
 175 |     category: 'personal_growth',
 176 |     emotionalTone: 'seeking'
 177 |   },
 178 |   {
 179 |     id: 'growth-2',
 180 |     question: '你从最大的失败中学到了什么？',
 181 |     reflection: '失败是最严厉也是最慈悲的老师，它强迫我们成长。',
 182 |     tags: ['failure', 'learning', 'resilience', 'wisdom', 'growth'],
 183 |     category: 'personal_growth',
 184 |     emotionalTone: 'contemplative'
 185 |   },
 186 |   {
 187 |     id: 'growth-3',
 188 |     question: '如果你可以重新开始，你会做什么不同的选择？',
 189 |     reflection: '重新开始的幻想往往揭示了我们对当下生活的真实感受。',
 190 |     tags: ['regret', 'choices', 'restart', 'wisdom', 'reflection'],
 191 |     category: 'personal_growth',
 192 |     emotionalTone: 'contemplative'
 193 |   }
 194 | ];
 195 | 
 196 | // 获取随机灵感卡片
 197 | export const getRandomInspirationCard = (): InspirationCard => {
 198 |   const randomIndex = Math.floor(Math.random() * INSPIRATION_CARDS.length);
 199 |   return INSPIRATION_CARDS[randomIndex];
 200 | };
 201 | 
 202 | // 根据标签获取相关卡片
 203 | export const getCardsByTags = (tags: string[], limit: number = 5): InspirationCard[] => {
 204 |   const matchingCards = INSPIRATION_CARDS.filter(card =>
 205 |     card.tags.some(tag => tags.includes(tag))
 206 |   );
 207 |   
 208 |   // 随机排序并限制数量
 209 |   return matchingCards
 210 |     .sort(() => Math.random() - 0.5)
 211 |     .slice(0, limit);
 212 | };
 213 | 
 214 | // 根据类别获取卡片
 215 | export const getCardsByCategory = (category: string): InspirationCard[] => {
 216 |   return INSPIRATION_CARDS.filter(card => card.category === category);
 217 | };
 218 | 
 219 | // 根据情感基调获取卡片
 220 | export const getCardsByTone = (tone: string): InspirationCard[] => {
 221 |   return INSPIRATION_CARDS.filter(card => card.emotionalTone === tone);
 222 | };

```

`staroracle-app_allreact/src/utils/mobileUtils.ts`:

```ts
   1 | import { Capacitor } from '@capacitor/core';
   2 | 
   3 | /**
   4 |  * 检测是否为移动端原生环境
   5 |  */
   6 | export const isMobileNative = () => {
   7 |   return Capacitor.isNativePlatform();
   8 | };
   9 | 
  10 | /**
  11 |  * 检测是否为iOS
  12 |  */
  13 | export const isIOS = () => {
  14 |   return Capacitor.getPlatform() === 'ios';
  15 | };
  16 | 
  17 | /**
  18 |  * 创建最高层级的Portal容器
  19 |  */
  20 | export const createTopLevelContainer = (): HTMLElement => {
  21 |   let container = document.getElementById('top-level-modals');
  22 |   
  23 |   if (!container) {
  24 |     container = document.createElement('div');
  25 |     container.id = 'top-level-modals';
  26 |     container.style.cssText = `
  27 |       position: fixed !important;
  28 |       top: 0 !important;
  29 |       left: 0 !important;
  30 |       right: 0 !important;
  31 |       bottom: 0 !important;
  32 |       z-index: 2147483647 !important;
  33 |       pointer-events: none !important;
  34 |       -webkit-transform: translateZ(0) !important;
  35 |       transform: translateZ(0) !important;
  36 |       -webkit-backface-visibility: hidden !important;
  37 |       backface-visibility: hidden !important;
  38 |     `;
  39 |     document.body.appendChild(container);
  40 |   }
  41 |   
  42 |   return container;
  43 | };
  44 | 
  45 | /**
  46 |  * 获取移动端特有的模态框样式
  47 |  */
  48 | export const getMobileModalStyles = () => {
  49 |   return {
  50 |     position: 'fixed' as const,
  51 |     zIndex: 2147483647, // 使用最大z-index值
  52 |     top: 0,
  53 |     left: 0,
  54 |     right: 0,
  55 |     bottom: 0,
  56 |     pointerEvents: 'auto' as const,
  57 |     WebkitTransform: 'translateZ(0)',
  58 |     transform: 'translateZ(0)',
  59 |     WebkitBackfaceVisibility: 'hidden' as const,
  60 |     backfaceVisibility: 'hidden' as const,
  61 |   };
  62 | };
  63 | 
  64 | /**
  65 |  * 获取移动端特有的CSS类名
  66 |  */
  67 | export const getMobileModalClasses = () => {
  68 |   return 'fixed inset-0 flex items-center justify-center';
  69 | };
  70 | 
  71 | /**
  72 |  * 强制隐藏所有其他元素（除了模态框）
  73 |  */
  74 | export const hideOtherElements = () => {
  75 |   if (!isIOS()) return () => {};
  76 |   
  77 |   // 如果Portal和z-index修复已经工作，我们可能不需要隐藏主页按钮
  78 |   // 让我们尝试一个最小化的方法：只在绝对必要时隐藏
  79 |   
  80 |   console.log('iOS hideOtherElements called - using minimal approach');
  81 |   
  82 |   // 返回一个空的恢复函数，不隐藏任何元素
  83 |   return () => {
  84 |     console.log('iOS hideOtherElements restore called');
  85 |   };
  86 | };
  87 | 
  88 | /**
  89 |  * 修复iOS层级问题的通用方案
  90 |  */
  91 | export const fixIOSZIndex = () => {
  92 |   if (!isIOS()) return;
  93 |   
  94 |   // 创建顶级容器
  95 |   createTopLevelContainer();
  96 |   
  97 |   // 为body添加特殊的层级修复
  98 |   document.body.style.webkitTransform = 'translateZ(0)';
  99 |   document.body.style.transform = 'translateZ(0)';
 100 | };

```

`staroracle-app_allreact/src/utils/oracleUtils.ts`:

```ts
   1 | // This function simulates generating a mystical, poetic response
   2 | // In a real app, this would connect to an AI service
   3 | export const generateOracleResponse = (): string => {
   4 |   const responses = [
   5 |     "The stars whisper of paths untaken, yet your journey remains true to your heart's calling.",
   6 |     "Like the moon's reflection on water, what you seek is both there and not there. Look deeper.",
   7 |     "Ancient light travels to reach your eyes; patience will reveal what haste conceals.",
   8 |     "The cosmos spins patterns of possibility. Your question already contains its answer.",
   9 |     "Celestial bodies dance in harmony despite distance. Find your rhythm in life's grand ballet.",
  10 |     "As galaxies spiral through the void, your path winds through darkness toward distant light.",
  11 |     "The nebula of your thoughts contains the seeds of stars yet unborn. Nurture them.",
  12 |     "Time flows like stellar winds, shaping the landscape of your existence into forms yet unknown.",
  13 |     "The void between stars is not empty but full of potential. Embrace the spaces in your life.",
  14 |     "Your question echoes across the cosmos, returning with wisdom carried on starlight.",
  15 |     "The universe expands without destination. Your journey needs no justification beyond itself.",
  16 |     "Constellations are patterns we impose on chaos. Create meaning from the random stars of experience.",
  17 |     "The light you see began its journey long ago. Trust in what is revealed, even if delayed.",
  18 |     "Cosmic dust becomes stars becomes dust again. All transformations are possible for you.",
  19 |     "The gravity of your intentions pulls experiences into orbit around you. Choose wisely what you attract.",
  20 |   ];
  21 |   
  22 |   return responses[Math.floor(Math.random() * responses.length)];
  23 | };

```

`staroracle-app_allreact/src/utils/soundUtils.ts`:

```ts
   1 | import { Howl } from 'howler';
   2 | 
   3 | // Sound URLs
   4 | const SOUND_URLS = {
   5 |   starClick: 'https://assets.codepen.io/21542/click-2.mp3',
   6 |   starLight: 'https://assets.codepen.io/21542/pop-up-on.mp3',
   7 |   starReveal: 'https://assets.codepen.io/21542/pop-down.mp3',
   8 |   ambient: 'https://assets.codepen.io/21542/ambient-loop.mp3',
   9 | };
  10 | 
  11 | // Preload sounds
  12 | const sounds: Record<string, Howl> = {};
  13 | 
  14 | Object.entries(SOUND_URLS).forEach(([key, url]) => {
  15 |   sounds[key] = new Howl({
  16 |     src: [url],
  17 |     volume: key === 'ambient' ? 0.2 : 0.5,
  18 |     loop: key === 'ambient',
  19 |   });
  20 | });
  21 | 
  22 | // Sound utility functions
  23 | export function playSound(
  24 |   soundName: 'starClick' | 'starLight' | 'starReveal' | 'ambient' | 'uiClick',
  25 |   options: { volume?: number; loop?: boolean } = {}
  26 | ) {
  27 |   // For uiClick, default to starClick if not available
  28 |   const actualSoundName = soundName === 'uiClick' ? 'starClick' : soundName;
  29 |   
  30 |   if (sounds[actualSoundName]) {
  31 |     // Set volume if provided
  32 |     if (options.volume !== undefined) {
  33 |       sounds[actualSoundName].volume(options.volume);
  34 |     }
  35 |     
  36 |     // Set loop if provided
  37 |     if (options.loop !== undefined) {
  38 |       sounds[actualSoundName].loop(options.loop);
  39 |     }
  40 |     
  41 |     // Play the sound
  42 |     sounds[actualSoundName].play();
  43 |     
  44 |     console.log(`🔊 Playing sound: ${soundName}`);
  45 |   } else {
  46 |     console.warn(`⚠️ Sound not found: ${soundName}`);
  47 |   }
  48 | }
  49 | 
  50 | export const stopSound = (soundName: keyof typeof SOUND_URLS) => {
  51 |   if (sounds[soundName]) {
  52 |     sounds[soundName].stop();
  53 |   }
  54 | };
  55 | 
  56 | export const startAmbientSound = () => {
  57 |   if (!sounds.ambient.playing()) {
  58 |     sounds.ambient.play();
  59 |   }
  60 | };
  61 | 
  62 | export const stopAmbientSound = () => {
  63 |   sounds.ambient.stop();
  64 | };

```

`staroracle-app_allreact/src/vite-env.d.ts`:

```ts
   1 | /// <reference types="vite/client" />
   2 | 
   3 | // 定义支持的API提供商类型
   4 | export type ApiProvider = 'openai' | 'gemini';
   5 | 
   6 | interface ImportMetaEnv {
   7 |   readonly VITE_DEFAULT_PROVIDER?: ApiProvider; // 新增：API提供商
   8 |   readonly VITE_DEFAULT_API_KEY?: string;
   9 |   readonly VITE_DEFAULT_ENDPOINT?: string;
  10 |   readonly VITE_DEFAULT_MODEL?: string;
  11 | }
  12 | 
  13 | interface ImportMeta {
  14 |   readonly env: ImportMeta;
  15 | }

```

`staroracle-app_allreact/tailwind.config.js`:

```js
   1 | /** @type {import('tailwindcss').Config} */
   2 | module.exports = {
   3 |   content: [
   4 |     './index.html', 
   5 |     './src/**/*.{js,ts,jsx,tsx,vue}',
   6 |     './pages/**/*.{js,ts,jsx,tsx,vue}',
   7 |     './components/**/*.{js,ts,jsx,tsx,vue}'
   8 |   ],
   9 |   theme: {
  10 |     extend: {
  11 |       fontFamily: {
  12 |         heading: ['Cinzel', 'serif'],
  13 |         body: ['Cormorant Garamond', 'serif'],
  14 |       },
  15 |       colors: {
  16 |         cosmic: {
  17 |           dark: '#090A0F',
  18 |           navy: '#1B2735',
  19 |           purple: '#5D4777',
  20 |           blue: '#2C5364',
  21 |           accent: '#8A5FBD',
  22 |         },
  23 |       },
  24 |       animation: {
  25 |         'float': 'float 6s ease-in-out infinite',
  26 |         'twinkle': 'twinkle 3s ease-in-out infinite',
  27 |         'pulse': 'pulse 2s infinite ease-in-out',
  28 |       },
  29 |       keyframes: {
  30 |         float: {
  31 |           '0%, 100%': { transform: 'translateY(0)' },
  32 |           '50%': { transform: 'translateY(-10px)' },
  33 |         },
  34 |         twinkle: {
  35 |           '0%, 100%': { opacity: '0.3' },
  36 |           '50%': { opacity: '1' },
  37 |         },
  38 |       },
  39 |     },
  40 |   },
  41 |   plugins: [],
  42 |   // 条件编译：只在H5端使用
  43 |   corePlugins: {
  44 |     preflight: process.env.UNI_PLATFORM === 'h5',
  45 |   }
  46 | }

```

`staroracle-app_allreact/tsconfig.app.json`:

```json
   1 | {
   2 |   "compilerOptions": {
   3 |     "target": "ES2020",
   4 |     "useDefineForClassFields": true,
   5 |     "lib": ["ES2020", "DOM", "DOM.Iterable"],
   6 |     "module": "ESNext",
   7 |     "skipLibCheck": true,
   8 | 
   9 |     /* Bundler mode */
  10 |     "moduleResolution": "bundler",
  11 |     "allowImportingTsExtensions": true,
  12 |     "isolatedModules": true,
  13 |     "moduleDetection": "force",
  14 |     "noEmit": true,
  15 |     "jsx": "react-jsx",
  16 | 
  17 |     /* Linting */
  18 |     "strict": true,
  19 |     "noUnusedLocals": true,
  20 |     "noUnusedParameters": true,
  21 |     "noFallthroughCasesInSwitch": true
  22 |   },
  23 |   "include": ["src"]
  24 | }

```

`staroracle-app_allreact/tsconfig.json`:

```json
   1 | {
   2 |   "files": [],
   3 |   "references": [
   4 |     { "path": "./tsconfig.app.json" },
   5 |     { "path": "./tsconfig.node.json" }
   6 |   ]
   7 | }

```

`staroracle-app_allreact/tsconfig.node.json`:

```json
   1 | {
   2 |   "compilerOptions": {
   3 |     "target": "ES2022",
   4 |     "lib": ["ES2023"],
   5 |     "module": "ESNext",
   6 |     "skipLibCheck": true,
   7 | 
   8 |     /* Bundler mode */
   9 |     "moduleResolution": "bundler",
  10 |     "allowImportingTsExtensions": true,
  11 |     "isolatedModules": true,
  12 |     "moduleDetection": "force",
  13 |     "noEmit": true,
  14 | 
  15 |     /* Linting */
  16 |     "strict": true,
  17 |     "noUnusedLocals": true,
  18 |     "noUnusedParameters": true,
  19 |     "noFallthroughCasesInSwitch": true
  20 |   },
  21 |   "include": ["vite.config.ts"]
  22 | }

```

`staroracle-app_allreact/vite.config.js`:

```js
   1 | import { defineConfig } from 'vite'
   2 | import react from '@vitejs/plugin-react'
   3 | import path from 'path'
   4 | 
   5 | // https://vitejs.dev/config/
   6 | export default defineConfig({
   7 |   plugins: [react()],
   8 |   resolve: {
   9 |     alias: {
  10 |       '@': path.resolve(__dirname, './src'),
  11 |     },
  12 |   },
  13 |   server: {
  14 |     port: 3000,
  15 |     host: '0.0.0.0',
  16 |     open: true
  17 |   }
  18 | })

```