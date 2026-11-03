<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/hero-dark.png">
    <img src="docs/images/hero-light.png" alt="Overview of the seven programs: text (TextDetection with a webcam, TextDetection4Ways on TEST.jpg, TextDetectionUsingProfile on 7.jpg), breathing (two neckline detectors) and heart rate (heartbeats and FaceAndHeartbeatDetection), all built with CMake against OpenCV 3.2.">
  </picture>
</p>

Seven small C++ programs written with [OpenCV](https://opencv.org/) for a group homework at National
Taiwan Ocean University (NTOU), Department of Computer Science and Engineering, between April and
June 2016. The commit history shows four authors: Nat (NatLee), WenShihKen, FinianWu and 張語航.
The programs try three things: reading text in an image, counting breaths by watching the neckline
on a webcam, and estimating a heart rate from the colour of skin.

The code is kept the way it was written, odd bits included. This README explains how each program
works, shows real results for the three that could be run here, and says how to build them today.

## Build

The programs were written in Visual Studio for OpenCV 3. They use OpenCV's old C API (`IplImage`,
`cvShowImage`, `cvCreateTrackbar`, …), which OpenCV 4 removed, and `TextDetection` needs the
`text` module from opencv_contrib. The easiest way to get that toolchain is the Dockerfile, which
uses Ubuntu 18.04, the last Ubuntu release that packages OpenCV 3 (3.2):

```sh
docker build -t ntou-cs-opencv-hw .     # builds all seven into /src/build in the image
```

With OpenCV 3 and its contrib modules installed yourself, CMake 3.10 or newer builds them natively:

```sh
mkdir build && cd build && cmake .. && make
```

Each folder becomes one program of the same name, e.g. `build/TextDetection4Ways`. CMake asks for
OpenCV 3, so pointing it at OpenCV 4 stops with a clear message. CI builds the Docker image on
every pull request and every push to `master`.

## Run

Start each program from its own folder, because it opens its input files by relative path:

```sh
cd TextDetection4Ways && ../build/TextDetection4Ways
```

| Program | Input | Also needs in its folder | Quit with |
| --- | --- | --- | --- |
| `TextDetection` | webcam | the OCR model files, see below | Ctrl+C |
| `TextDetection4Ways` | `TEST.jpg` | `0.txt` … `9.txt` (in the repo) | Ctrl+C |
| `TextDetectionUsingProfile` | `7.jpg` | — | any key |
| `NecklineDetectionUsingNormalMethod` | webcam | — | any key |
| `NecklineDetectionUsingOpticalFlow` | webcam | — | any key |
| `heartbeats` | webcam | — | any key |
| `FaceAndHeartbeatDetection` | webcam | two Haar cascade files, see below | Esc |

`TextDetection` uses the CNN character classifier and language model that ship with
opencv_contrib 3.2.0:

```sh
cd TextDetection
curl -LO https://raw.githubusercontent.com/opencv/opencv_contrib/3.2.0/modules/text/samples/OCRBeamSearch_CNN_model_data.xml.gz
curl -LO https://raw.githubusercontent.com/opencv/opencv_contrib/3.2.0/modules/text/samples/OCRHMM_transitions_table.xml
```

`FaceAndHeartbeatDetection` loads two of the Haar cascades that come with OpenCV. On Ubuntu they
are in the `opencv-data` package:

```sh
cp /usr/share/opencv/haarcascades/haarcascade_frontalface_alt.xml \
   /usr/share/opencv/haarcascades/haarcascade_eye_tree_eyeglasses.xml FaceAndHeartbeatDetection/
```

`.gitignore` keeps these downloaded files out of git. Without a webcam, the five camera programs
stop right away.

## Project layout

```text
.
├── TextDetection/                       webcam OCR: main.cpp, TextDetection.cpp, TEXTRecognizer.cpp
├── TextDetection4Ways/                  digits by quadrants: Source.cpp (includes thinning.cpp),
│   ├── TEST.jpg, 1.jpg                  the test image the code reads, and one more,
│   ├── 0.txt … 9.txt                    one template per digit,
│   └── HandWrite/                       and ten handwritten templates per digit (not read by the code)
├── TextDetectionUsingProfile/           lines by projection: Source.cpp and 7.jpg
├── NecklineDetectionUsingNormalMethod/  breathing: NecklineDetection.cpp
├── NecklineDetectionUsingOpticalFlow/   breathing with optical flow: NecklineOpticalFlow.cpp, find_collar.cpp
├── heartbeats/                          heart rate from the biggest skin area
├── FaceAndHeartbeatDetection/           heart rate inside a detected face
├── docs/images/                         README pictures; their HTML sources and render.sh are in src/
├── CMakeLists.txt                       one executable per folder
├── Dockerfile                           Ubuntu 18.04 + OpenCV 3.2 toolchain, used by CI
└── .github/workflows/build.yml          CI: builds the Docker image
```

## Reading text

### TextDetection4Ways: digits by quadrants

No OCR library here. The program finds the line of text and the characters with projections, then
recognises each digit by how its ink is spread over four quadrants, compared with one template per
digit. Every picture on the right is a window the program really shows.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/text-4ways-dark.png">
    <img src="docs/images/text-4ways-light.png" alt="TextDetection4Ways step by step: TEST.jpg with the digits 0 to 9 and a second 8; the strokes after grey minus erosion, threshold and flood fill; the text line found by row projection, after one thinning pass; eleven red boxes found by column projection; a box cut into four quadrants with the ink shares 0.27, 0.21, 0.29, 0.23 compared with 0.txt to 9.txt; and the printed result 0 1 2 3 4 5 6 7 0 0 5, eight of eleven right.">
  </picture>
</p>

```text
$ cd TextDetection4Ways && ../build/TextDetection4Ways
/////////////
0
1
2
3
4
5
6
7
0
0
5
```

`TEST.jpg` shows 0 1 2 3 4 5 6 7 8 8 9, so 8 of the 11 are right.

### TextDetectionUsingProfile: lines by projection

Counts the ink in every row of a shop receipt to find the lines, then in every column of each line
to find blocks.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/text-profile-dark.png">
    <img src="docs/images/text-profile-light.png" alt="TextDetectionUsingProfile: binarise with Otsu, count white pixels per row to find the 14 lines of the receipt, then dilate and count per column to find blocks. 7.jpg is shown with the 14 rows and the six blocks the program computed, next to its gray window, where repeated dilation has melted the text into bars.">
  </picture>
</p>

The row step finds all 14 lines of the receipt. The block step does not get far, and the program
draws its boxes in the wrong place; the two notes in the picture say why. The rows and blocks on the
left picture are the program's own numbers, printed by a copy of `Source.cpp` with two `printf`
lines added.

### TextDetection: webcam OCR

Shows the webcam with a red box. Hold some text inside it and press c: the frame freezes, and every
character-sized blob inside the box gets a letter from the CNN classifier in opencv_contrib's text
module. Press any other key to go back to the live view.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/text-ocr-dark.png">
    <img src="docs/images/text-ocr-light.png" alt="TextDetection: freeze a frame, adaptive threshold and clearDots, keep blobs close to the average size of the five biggest, classify each with the CNN classifier. A test frame with TEST.jpg inside the red box gives O L 2 B 4 S 6 7 8 S 9 for 0 1 2 3 4 5 6 7 8 8 9.">
  </picture>
</p>

There was no webcam for this README, so the run in the picture put `TEST.jpg` (scaled to 300 px
wide) into a blank 640 × 480 frame and called the program's own `textDetection()` on it. The
classifier knows letters as well as digits, so 0, 1, 3 and 5 come out as O, L, B and S.

## Counting breaths

`NecklineDetectionUsingNormalMethod` and `NecklineDetectionUsingOpticalFlow` find the skin of the
neck and watch where it meets the collar. Breathing moves that line up and down.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/breathing-dark.png">
    <img src="docs/images/breathing-light.png" alt="Counting breaths, schematic: find skin in YCrCb, scan from the bottom right for the first row with 120 skin pixels in a row, trace the collar up to 50 pixels below it, and count a half breath each time the row changes direction after moving more than 5 pixels. The normal method paints the neckline and prints 呼吸次數; the optical-flow version draws Farneback flow along the collar and prints up or down.">
  </picture>
</p>

Both need a webcam, so the picture is a schematic drawn from the code. The skin colour range can be
tuned with the trackbars in the Control window.

## Estimating a heart rate

`heartbeats` and `FaceAndHeartbeatDetection` average the red channel of the skin pixels in one area
of the frame and count how often that average turns from rising to falling and back.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/heartbeat-dark.png">
    <img src="docs/images/heartbeat-light.png" alt="Heart rate from skin colour, schematic: heartbeats uses the top half of the largest skin area, FaceAndHeartbeatDetection the box of a face found by a Haar cascade. Every frame the average red of the skin pixels is compared with the previous frame; each change of direction is a flip, two flips are a beat, and beats divided by seconds from clock() times 60 is drawn on the frame.">
  </picture>
</p>

This is a schematic as well; the curve is an illustration, not a measurement.

## Odd bits, kept as they were

The code was not changed to fix these. They are listed so the results above make sense.

| Program | What you see | Why |
| --- | --- | --- |
| TextDetection4Ways | both 8s read as 0, the 9 as 5 | one template per digit, and the 0 and 8 templates are nearly the same |
| TextDetection4Ways | never exits by itself | the main loop reads `TEST.jpg` again after every key |
| TextDetectionUsingProfile | no boxes on the receipt | `cvDrawRect(src, rect.x, rect.y, …)` gets two numbers instead of two corners, so each box is a line on the top pixel row |
| TextDetectionUsingProfile | blocks only for the first six lines | each line's block search dilates the whole image again |
| TextDetection | letters for digits (O, L, B, S) | the classifier has 62 classes: a–z, A–Z, 0–9 |
| heartbeats, FaceAndHeartbeatDetection | rate depends on CPU load | seconds come from `clock()`, the processor time used |
| FaceAndHeartbeatDetection | only part of the face is averaged | the pixel loop stops at `faces[0].y + width` instead of `x + width` |
| both neckline programs | dragging HighCb moves the low bound | the trackbar is tied to `&LCb` |

## History

Written between 2016-04-24 and 2016-06-29 in Visual Studio with OpenCV 3; the project files were
never committed. In 2026 two Visual C++-only spots were replaced with standard C++ (a `for each`
loop and an include path), two Big5-encoded files were converted to UTF-8, and CMake, a Docker
toolchain, CI and this README were added. Nothing else in the programs changed.

## License

[MIT](LICENSE)
