'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "8292d1f166f8312686062aadc2fddbbc",
".git/config": "8e9d6c83e12f515eadaef7fd508e7adb",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "ea587b0fae70333bce92257152996e70",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "de81a06e6209cb1d55983aac68ea0f81",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "4d24b925963e7afb1fa6d23c4154d8be",
".git/logs/refs/heads/main": "3dbd6e823d4689d208f6e9fa311af25f",
".git/logs/refs/remotes/origin/main": "676a07ce73494f3f65cccd162ead9e7e",
".git/objects/03/198282e84cdcef9e98a38f882f04ac3e4f8f7f": "384911e8f3ac8511b92d7defaf354225",
".git/objects/0a/4ca27360ae85b659156d13f1ff5e30b2c5588b": "d4c56761912830f56b25f2c890c7acd8",
".git/objects/10/3dd128a292b390abc4b129b891f5e0108954d9": "e83cbf7dc3c5fb7fec6eed64783d66f1",
".git/objects/19/024f177911cdfca418c2a3afef750336efaa2e": "8936578c793c0f52a969a7ca8b39c192",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "94fdc36a022769ae6a8c6c98e87b3452",
".git/objects/23/cfb7609512108b272615768a93977f5d108821": "580fafa8264beca442fa6eac89f8fd2f",
".git/objects/2b/2afcf09734e0ce8cf7effa6c7303bc2add6f11": "73743214829a96146579172ffe530f0e",
".git/objects/33/4c68fcf0fb9fe8c767d02782ff346c60a268a7": "2e9427a322a126d19a48f56f337439ef",
".git/objects/3d/6518daba860086663a92d33e9438173d7f3bf5": "3c3a3bd3afb7ff66eb3b89c0f760976c",
".git/objects/46/0b968e61958c73744e9073ebcfc33e9ebb8a7d": "9a43793be954dd5b79cc1a9d196126fa",
".git/objects/46/3fecf5ad1364a332376150e59d667594d1754f": "ee390efdd9dd72dc9b40681458ac75da",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/4c/51fb2d35630595c50f37c2bf5e1ceaf14c1a1e": "a20985c22880b353a0e347c2c6382997",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "a686c83ba0910f09872b90fd86a98a8f",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "4592c949830452e9c2bb87f305940304",
".git/objects/53/df08c80eece3b28e00ffd99c3587d7545c0a7e": "1d916eaa60c74b3358671c3bf7811a30",
".git/objects/54/1dfe42d7a569beade6e2bbdc339200604a1e0b": "a072cefaa406efac826e5f01ad7c9539",
".git/objects/55/5bb2a0264a4c3d8d42dee231976acf7efd64fa": "c6e9b3715096e35f8f2f26b748a6c38e",
".git/objects/59/8324e460dd843800b9488cc2aec9ec127f1503": "9c280bfdf28c466463eb156ae5e22aa6",
".git/objects/63/baa82a77664f8a01bf42297ed7410feba0d948": "b791ed5f81f91cc49fccd9ab5881c06a",
".git/objects/67/1070bed62aa41397ea05a1cbbc92f79f41d88f": "dda5bfd27c0c264dad4e637690195b62",
".git/objects/6b/5e7e6836e7d00a6a29a42a6d528d38161cb6c1": "adedf4edaa4d99cde95c7170952327ff",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/70/2571fab4a8019e9d08e451c52840ace00d7660": "09559d664dcfc1f1a322dfda6211e41b",
".git/objects/70/553423a77e96a9f64224f0237017b0f9bf1ca0": "10e8c6528b8cdf5426b951f5191fcf4b",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "6ae390f0843274091d1e2838d9399c51",
".git/objects/74/c3f36064423300b74fe0bd8e6430443ef09d7b": "bfe5fa3468a8a19b6cef6733865cd5d5",
".git/objects/78/2a9d65aa77027ff8fa0d9264750d4490f1c7bc": "3882b4fc99d3373fdb84f59c503aa387",
".git/objects/7d/642ab8e4323286e6f992113bb3d60e0261ee0f": "b6a3c2a36ae114bf787c02bf21a53aba",
".git/objects/7f/c3f1715f6910cde2937949941989ed8efec9e8": "85d7443733d9dc286a3973a71edd082f",
".git/objects/80/2ed525508bc19baab9e891d29bc30127153d20": "4ca065777c73587a4566be21fb2342fc",
".git/objects/80/cb850ddf064111cdc6e1f8ab236bfb3c35a90e": "1a9c05c839a0ab56c9cab67a00ad758f",
".git/objects/84/d4bc85da77c33be3e5b6e381f94be93efd6a6a": "4c55f4a8b25b1c6d33ae097c5f106a4c",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8e/3c7d6bbbef6e7cefcdd4df877e7ed0ee4af46e": "025a3d8b84f839de674cd3567fdb7b1b",
".git/objects/95/9385c9ef203f7957792cfb0d666f4c981c345c": "dca64bb6390a6dddcc1c57f20204efa9",
".git/objects/97/5be37eb009c24c41cd1646a5d4b339c43fd340": "4454471a87f056f61546d9fa8d85c8d8",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/a6/a0073e7b35496319b9aef71b6c4e4a883a29c8": "efe405468f90e0dbe3d7445d635cedb1",
".git/objects/a7/c22dcc402360d872fdafcff50cbbabccc3c311": "d27f3c82ae451d6ad086bd2e38885c3f",
".git/objects/a8/9620cfc2de4e97933f4bb3418e454d0fddebcf": "f8e3760a969a278975d102d1cf2e7875",
".git/objects/af/0cb447c9f0fb138836e205f5debcd61f7926fc": "7c140566efa33c5b289220c4b0fd4ac2",
".git/objects/af/8b068c837a6ededeea722986c1309cab84bff5": "020b53f1dd79494b72c9abd06fa0453d",
".git/objects/b1/0d1a2dd162d3cf05a499628cd3c293f3d59733": "43286bd80d9a579794766f5bc2854ba4",
".git/objects/b4/89fce93ba225be9d819619a86ff239dc8e905d": "8749854177bbcf5bd8f5981ee00ddca8",
".git/objects/b5/c033fa0303de44927b5ef399bff93a335a0f1c": "6caf1ae683d07c8b7c3426d2df408dd6",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/ba/6738d12805203a0846a1c38ab9949d3c3ca310": "8ad3ad01b4fcb564b5b570f4f11e643b",
".git/objects/bb/30d53ebbf24d2903ec6f2988cde35cff5b1abe": "1eb3d68bd2a6ee9903915a1f619d4038",
".git/objects/bd/c9a638d638f29f5eba01747d9b12576c5d04c0": "ca2ea5e0cbcd046d24416e28762f29b6",
".git/objects/c7/6dc4976ad4cac5c8fde923d6081aaff26611b7": "00f83371a6c0c5bd5560ea598db5b47f",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "92cdd8b3553e66b1f3185e40eb77684e",
".git/objects/ce/345ff0973d5696ba718a033ab22e791d56e054": "7dce20c12b520ff2f3366bea22bc0072",
".git/objects/d3/cafee5619a64d920aa9b5cd00dada7c4950e0a": "3cbc024f131774d81034d11f6b18d607",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d8/4187bf71d5e6a3845dca5a785a08a19a4639a9": "863eb51e5c85a00f0b1ba18bd666ad09",
".git/objects/d8/e54f0606148f6ef7702ca4c850e1a806484a0c": "9f087c57ae52d3ebf09bebdc2d38d198",
".git/objects/da/1aebb8835aca7b3e4e802ece9d3597c1def8ba": "47588989fc74fdfd930f2211f4d0edbc",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "74ebcb23eb10724ed101c9ff99cfa39f",
".git/objects/e1/32fdc5606c4f7448e57e70af20b907f1b6f1fb": "ebb9077af6687efc5d0b84f621300d69",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ec/a64e33a68c09c69be3376dba28c961f7e66a95": "6e3616eb18b969aaac847ea594a4d27d",
".git/objects/f0/88be99c9cbed6761483442cb9575196f4d79dd": "405f203035fcb35206d596ae48df66ea",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fb/7757817f5464aa0c6aac24d96945542525042f": "20440bf91c2bcce7c2e6cba310dc7dbe",
".git/objects/fb/f4ef24a61349b695736a1c0dde2d34af617956": "d4e0a8b61102583dd021115f30dc6307",
".git/refs/heads/main": "273d330ca371bddf42fc0ce7b21c1ca4",
".git/refs/remotes/origin/main": "273d330ca371bddf42fc0ce7b21c1ca4",
"assets/AssetManifest.bin": "bda69b2d94259a62c8374769b8373c49",
"assets/AssetManifest.bin.json": "1f17fcf8fa0f6e563df96725fec3c72e",
"assets/AssetManifest.json": "491f300584ee76691ac1f791d93d4b8e",
"assets/assets/logo.png": "5e8de7f326230986ac0b22d73a2685db",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "ea2077bf094930262b19ba3d14073da8",
"assets/NOTICES": "4e01e8c7dcf59e3301dc27736376d29d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "b26dcdc46d439acd0e29cb1e78c4edc1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "c2b85cbdce1030b6becc0a6eb8a01382",
"/": "c2b85cbdce1030b6becc0a6eb8a01382",
"main.dart.js": "17fb1afcf8982353fd499f2b59f5ea82",
"manifest.json": "65b4be2c44203b0210d271ccc4a50037",
"version.json": "4ad5f98d28434edd82147c5a39aa54bb"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
