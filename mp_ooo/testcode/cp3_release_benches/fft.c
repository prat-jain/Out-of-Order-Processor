#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

// #define N 512







// Define fixed-point representation
#define Q 15  // Q-factor for fixed-point arithmetic
#define F (1 << Q)  // Fixed-point scale factor

typedef struct {
    int16_t real;
    int16_t imag;
} complex_int16;

// Function to perform the FFT
void fft(complex_int16 data[], int n, int l) {
    if (n <= 1) return;

    complex_int16 even[n/2], odd[n/2];
    for (int i = 0; i < n/2; i++) {
        even[i] = data[2*i];
        odd[i] = data[2*i+1];
    }

    fft(even, n/2, l-1);
    fft(odd, n/2, l-1);

    int16_t theta = -32768 >> l; // 2 * PI in Q15 format
    complex_int16 w = {F, 0};
    complex_int16 wn = {(int16_t)(F * (theta)), (int16_t)(F * (theta))};

    for (int i = 0; i < n/2; i++) {
        complex_int16 temp = {(int16_t)((int32_t)w.real * odd[i].real - (int32_t)w.imag * odd[i].imag) / F,
                              (int16_t)((int32_t)w.real * odd[i].imag + (int32_t)w.imag * odd[i].real) / F};
        data[i].real = (int16_t)((int32_t)even[i].real + (int32_t)temp.real) / F;
        data[i].imag = (int16_t)((int32_t)even[i].imag + (int32_t)temp.imag) / F;
        data[i + n/2].real = (int16_t)((int32_t)even[i].real - (int32_t)temp.real) / F;
        data[i + n/2].imag = (int16_t)((int32_t)even[i].imag - (int32_t)temp.imag) / F;
        w.real = (int16_t)(((int32_t)w.real * wn.real - (int32_t)w.imag * wn.imag) / F);
        w.imag = (int16_t)(((int32_t)w.real * wn.imag + (int32_t)w.imag * wn.real) / F);
    }
}

int main() {

    
    int16_t alldata_0 [1024] = {764, 217, 919, 154, 451, 925, 47, 335, 716, 808, 424, 844, 853, 815, 12, 367,
                            184, 685, 197, 312, 383, 266, 112, 790, 124, 273, 821, 363, 746, 67, 882, 253,
                            455, 503, 356, 111, 447, 888, 856, 232, 45, 119, 180, 842, 354, 280, 831, 232,
                            287, 640, 773, 213, 331, 726, 841, 214, 929, 972, 779, 303, 46, 751, 285, 745,
                            513, 562, 866, 666, 462, 293, 839, 153, 137, 926, 157, 232, 762, 721, 734, 503,
                            453, 407, 851, 290, 232, 958, 219, 877, 2, 356, 868, 925, 779, 805, 806, 986,
                            50, 322, 809, 338, 196, 154, 966, 730, 950, 316, 293, 230, 872, 645, 719, 300,
                            878, 299, 199, 115, 147, 693, 136, 868, 28, 472, 140, 144, 398, 908, 539, 275,
                            277, 652, 279, 984, 21, 592, 461, 990, 6, 827, 825, 613, 970, 224, 117, 675,
                            499, 231, 223, 27, 249, 987, 651, 971, 89, 652, 677, 72, 795, 167, 12, 975,
                            454, 892, 91, 913, 841, 219, 480, 922, 686, 744, 373, 334, 727, 281, 681, 98,
                            496, 229, 453, 623, 854, 766, 763, 628, 131, 366, 465, 346, 828, 485, 615, 451,
                            321, 489, 24, 87, 653, 732, 889, 789, 812, 72, 37, 456, 10, 941, 181, 762,
                            577, 321, 486, 383, 439, 107, 329, 718, 38, 495, 517, 757, 787, 855, 641, 483,
                            901, 901, 255, 72, 667, 856, 480, 844, 475, 541, 673, 410, 676, 731, 490, 741,
                            201, 960, 460, 145, 317, 320, 317, 852, 421, 293, 703, 875, 30, 247, 143, 807,
                            473, 365, 976, 731, 886, 166, 869, 117, 628, 877, 269, 821, 464, 574, 190, 818,
                            917, 321, 63, 859, 723, 99, 432, 299, 256, 707, 341, 464, 770, 208, 58, 284,
                            961, 721, 326, 87, 399, 246, 285, 116, 540, 936, 550, 913, 357, 175, 266, 343,
                            175, 139, 987, 54, 623, 415, 946, 559, 633, 662, 247, 583, 300, 899, 781, 476,
                            398, 514, 315, 458, 699, 652, 962, 728, 570, 333, 273, 488, 370, 849, 72, 639,
                            255, 124, 641, 878, 779, 569, 473, 998, 115, 351, 404, 42, 36, 247, 709, 71,
                            691, 565, 249, 413, 700, 623, 892, 793, 632, 164, 726, 914, 478, 912, 932, 490,
                            272, 311, 193, 8, 178, 351, 360, 646, 643, 460, 367, 919, 387, 909, 142, 1,
                            399, 891, 68, 978, 130, 590, 745, 849, 300, 236, 174, 309, 871, 824, 947, 722,
                            992, 816, 893, 757, 885, 796, 115, 888, 264, 572, 861, 638, 143, 617, 60, 425,
                            330, 460, 334, 638, 500, 990, 678, 334, 571, 136, 593, 691, 577, 726, 203, 263,
                            918, 763, 12, 141, 832, 929, 687, 153, 946, 536, 368, 417, 838, 910, 302, 626,
                            66, 724, 809, 256, 111, 734, 585, 3, 349, 311, 352, 20, 598, 676, 365, 260,
                            131, 790, 72, 951, 425, 457, 209, 416, 570, 645, 40, 151, 919, 923, 597, 568,
                            932, 557, 564, 384, 538, 607, 580, 226, 17, 667, 190, 328, 110, 8, 74, 860,
                            110, 707, 649, 571, 727, 105, 212, 472, 364, 576, 527, 696, 297, 646, 721, 475,
                            367, 360, 199, 111, 154, 638, 144, 860, 392, 909, 988, 341, 923, 984, 560, 464,
                            250, 399, 243, 415, 483, 269, 854, 658, 859, 765, 109, 175, 222, 207, 216, 323,
                            19, 980, 241, 682, 558, 350, 425, 323, 878, 11, 684, 895, 16, 528, 905, 137,
                            83, 910, 167, 789, 657, 895, 745, 140, 874, 395, 370, 610, 555, 615, 693, 694,
                            550, 636, 668, 209, 850, 340, 552, 657, 792, 795, 203, 148, 116, 744, 770, 608,
                            458, 251, 393, 495, 926, 78, 123, 67, 432, 360, 609, 279, 994, 276, 500, 224,
                            785, 404, 465, 770, 368, 81, 713, 637, 507, 409, 253, 416, 420, 495, 133, 920,
                            643, 447, 703, 506, 285, 397, 914, 353, 345, 566, 343, 605, 998, 66, 395, 247,
                            721, 643, 53, 18, 900, 132, 29, 700, 918, 497, 484, 255, 776, 527, 743, 954,
                            319, 661, 826, 698, 523, 933, 691, 761, 49, 214, 238, 766, 656, 804, 626, 535,
                            513, 464, 851, 761, 133, 755, 226, 127, 415, 540, 140, 587, 707, 700, 442, 567,
                            134, 434, 131, 514, 625, 572, 684, 779, 183, 198, 640, 858, 218, 331, 411, 747,
                            4, 840, 110, 710, 714, 985, 662, 240, 542, 380, 104, 301, 468, 491, 199, 250,
                            765, 814, 517, 315, 452, 303, 269, 780, 323, 318, 863, 839, 599, 693, 208, 902,
                            914, 97, 583, 528, 345, 753, 729, 388, 807, 825, 817, 230, 101, 335, 674, 15,
                            394, 978, 713, 653, 703, 645, 407, 134, 764, 605, 699, 188, 980, 286, 763, 665,
                            482, 573, 433, 842, 776, 335, 929, 658, 555, 207, 952, 831, 891, 778, 834, 298,
                            766, 889, 863, 339, 628, 988, 126, 373, 817, 214, 134, 774, 115, 158, 836, 447,
                            132, 935, 529, 159, 640, 221, 895, 140, 438, 967, 157, 418, 526, 240, 692, 335,
                            45, 621, 580, 51, 771, 199, 839, 277, 998, 394, 642, 374, 910, 932, 105, 126,
                            737, 408, 565, 69, 688, 435, 796, 236, 982, 306, 205, 525, 358, 38, 17, 220,
                            827, 553, 928, 406, 329, 699, 376, 780, 555, 760, 52, 805, 442, 765, 261, 528,
                            444, 329, 531, 804, 978, 624, 877, 737, 968, 35, 913, 975, 291, 566, 414, 477,
                            751, 329, 622, 733, 359, 539, 617, 279, 854, 529, 676, 603, 385, 39, 549, 122,
                            734, 659, 983, 513, 245, 754, 37, 985, 442, 555, 654, 666, 449, 237, 306, 625,
                            930, 408, 546, 855, 211, 324, 251, 476, 517, 269, 19, 67, 980, 763, 653, 820,
                            103, 711, 865, 540, 276, 288, 306, 218, 138, 991, 986, 163, 177, 183, 779, 23,
                            594, 854, 479, 390, 663, 603, 455, 338, 563, 727, 132, 647, 966, 76, 565, 285,
                            997, 324, 526, 126, 192, 280, 893, 42, 343, 735, 123, 396, 34, 988, 2, 82,
                            983, 82, 428, 143, 378, 852, 936, 825, 225, 511, 891, 622, 386, 828, 154, 823,
                            763, 557, 355, 405, 280, 22, 384, 623, 94, 647, 503, 161, 960, 645, 84, 506,
                            44, 39, 16, 338, 485, 303, 428, 911, 98, 551, 756, 804, 137, 305, 549, 449,
                            };

    complex_int16 signal_0 [512];

    
    int16_t alldata_1 [1024] = {271, 797, 176, 821, 551, 577, 699, 970, 666, 422, 650, 914, 980, 9, 279, 327,
                            640, 778, 446, 615, 724, 863, 324, 584, 48, 545, 498, 300, 965, 310, 889, 394,
                            555, 580, 684, 803, 831, 31, 18, 700, 109, 76, 561, 811, 798, 986, 901, 72,
                            854, 658, 548, 294, 799, 351, 413, 712, 510, 405, 476, 90, 205, 916, 282, 464,
                            971, 344, 563, 15, 991, 214, 885, 536, 848, 784, 203, 88, 28, 650, 554, 873,
                            867, 531, 848, 463, 702, 278, 589, 779, 68, 625, 815, 497, 457, 111, 700, 4,
                            191, 334, 854, 357, 445, 593, 416, 750, 918, 833, 439, 715, 485, 609, 243, 213,
                            295, 325, 718, 218, 363, 219, 361, 578, 121, 669, 347, 884, 302, 35, 105, 14,
                            120, 286, 966, 817, 788, 339, 397, 85, 261, 705, 831, 112, 322, 986, 207, 786,
                            597, 284, 848, 73, 973, 685, 976, 685, 961, 952, 598, 693, 706, 95, 820, 35,
                            152, 700, 170, 67, 114, 202, 357, 778, 202, 630, 969, 884, 516, 732, 990, 511,
                            713, 665, 509, 90, 12, 100, 67, 693, 429, 191, 153, 534, 81, 213, 814, 158,
                            770, 244, 264, 490, 649, 728, 1, 393, 26, 369, 315, 393, 125, 186, 271, 896,
                            383, 820, 188, 532, 561, 144, 991, 241, 652, 267, 74, 145, 595, 225, 725, 955,
                            3, 866, 751, 500, 859, 602, 575, 100, 482, 134, 907, 271, 341, 308, 843, 112,
                            841, 819, 860, 600, 437, 785, 361, 392, 770, 769, 792, 807, 608, 249, 112, 377,
                            723, 206, 468, 101, 861, 218, 501, 54, 93, 797, 763, 921, 220, 296, 370, 659,
                            971, 8, 277, 99, 176, 741, 927, 326, 73, 935, 673, 993, 304, 2, 518, 144,
                            893, 188, 792, 807, 406, 612, 567, 256, 761, 822, 354, 155, 62, 112, 918, 55,
                            981, 420, 609, 148, 466, 944, 654, 563, 966, 253, 474, 997, 594, 812, 281, 404,
                            542, 423, 955, 775, 477, 35, 724, 500, 159, 517, 851, 550, 73, 466, 406, 125,
                            900, 909, 828, 439, 543, 667, 9, 146, 277, 92, 85, 153, 232, 5, 510, 896,
                            494, 81, 286, 869, 271, 586, 863, 522, 697, 734, 447, 333, 966, 153, 819, 921,
                            800, 689, 58, 510, 558, 452, 255, 628, 971, 307, 262, 347, 918, 191, 206, 781,
                            922, 324, 944, 183, 963, 170, 129, 590, 645, 795, 202, 754, 118, 568, 388, 836,
                            628, 300, 247, 835, 952, 358, 369, 321, 711, 376, 214, 387, 589, 157, 254, 207,
                            754, 124, 605, 313, 853, 644, 609, 732, 577, 426, 997, 925, 682, 80, 387, 738,
                            612, 762, 778, 230, 804, 286, 608, 462, 668, 624, 291, 726, 203, 725, 417, 334,
                            394, 182, 749, 819, 525, 857, 25, 291, 688, 797, 47, 672, 53, 505, 37, 71,
                            720, 730, 67, 572, 346, 462, 300, 692, 355, 340, 135, 178, 993, 208, 5, 126,
                            530, 615, 364, 222, 827, 702, 971, 162, 770, 713, 60, 723, 843, 265, 916, 730,
                            532, 710, 663, 92, 979, 916, 697, 310, 614, 800, 162, 200, 118, 800, 925, 610,
                            248, 946, 532, 359, 287, 827, 321, 314, 84, 427, 799, 696, 556, 826, 208, 454,
                            3, 762, 110, 162, 426, 253, 937, 365, 850, 357, 164, 872, 709, 947, 38, 352,
                            163, 312, 54, 415, 24, 155, 55, 360, 778, 907, 416, 970, 979, 342, 833, 56,
                            701, 384, 234, 503, 554, 386, 320, 770, 575, 409, 549, 87, 178, 303, 433, 204,
                            889, 159, 112, 315, 770, 63, 812, 503, 265, 299, 457, 581, 988, 466, 50, 664,
                            607, 517, 651, 115, 165, 454, 441, 42, 851, 986, 823, 470, 721, 321, 597, 728,
                            228, 862, 39, 937, 120, 754, 874, 114, 282, 214, 883, 144, 553, 96, 582, 935,
                            674, 261, 331, 341, 237, 890, 405, 720, 288, 718, 205, 684, 917, 946, 153, 408,
                            316, 404, 872, 431, 339, 444, 84, 455, 169, 836, 183, 630, 452, 210, 756, 601,
                            216, 101, 257, 661, 710, 393, 511, 182, 422, 201, 21, 731, 370, 857, 968, 687,
                            462, 716, 899, 207, 54, 834, 743, 320, 104, 898, 950, 130, 57, 621, 958, 902,
                            994, 240, 161, 328, 524, 943, 97, 762, 636, 31, 389, 596, 494, 537, 840, 891,
                            49, 64, 235, 82, 399, 650, 225, 763, 186, 131, 814, 942, 250, 626, 130, 649,
                            306, 436, 306, 858, 527, 28, 941, 677, 42, 832, 285, 526, 311, 278, 459, 656,
                            531, 924, 949, 957, 818, 97, 449, 716, 828, 637, 3, 625, 114, 836, 698, 313,
                            102, 685, 954, 574, 945, 523, 635, 257, 864, 358, 127, 866, 102, 931, 262, 540,
                            403, 648, 227, 812, 710, 168, 932, 503, 783, 759, 298, 556, 820, 763, 766, 703,
                            186, 574, 833, 4, 142, 535, 549, 973, 948, 710, 46, 699, 519, 106, 879, 777,
                            968, 610, 607, 807, 68, 756, 725, 467, 118, 323, 568, 733, 492, 775, 810, 951,
                            586, 664, 932, 853, 17, 542, 692, 261, 658, 830, 8, 245, 909, 395, 17, 335,
                            151, 153, 586, 114, 838, 317, 306, 245, 320, 905, 44, 107, 334, 126, 116, 190,
                            645, 675, 859, 197, 320, 794, 200, 528, 62, 443, 762, 463, 383, 102, 137, 474,
                            384, 298, 31, 508, 784, 565, 813, 135, 94, 107, 202, 821, 784, 506, 675, 905,
                            428, 982, 266, 708, 529, 732, 701, 434, 292, 30, 711, 256, 779, 629, 351, 564,
                            568, 454, 22, 581, 803, 927, 703, 954, 388, 402, 313, 320, 348, 688, 280, 696,
                            840, 295, 72, 480, 738, 345, 250, 419, 862, 153, 71, 888, 649, 290, 876, 283,
                            157, 360, 984, 431, 101, 466, 752, 917, 801, 42, 287, 263, 779, 13, 700, 550,
                            617, 390, 328, 767, 660, 403, 624, 344, 672, 665, 895, 715, 305, 696, 941, 511,
                            686, 757, 361, 677, 371, 173, 377, 999, 869, 666, 992, 758, 153, 726, 426, 248,
                            624, 964, 622, 583, 551, 505, 686, 952, 647, 155, 308, 399, 232, 78, 40, 577,
                            531, 400, 400, 761, 90, 114, 13, 255, 684, 200, 403, 888, 445, 689, 720, 349,
                            445, 583, 766, 280, 673, 565, 984, 468, 859, 946, 942, 198, 483, 815, 566, 840,
                            };

    complex_int16 signal_1 [512];

    
    int16_t alldata_2 [1024] = {107, 491, 582, 267, 705, 33, 893, 7, 799, 469, 181, 9, 948, 157, 751, 883,
                            553, 494, 691, 564, 168, 928, 925, 326, 53, 58, 456, 555, 824, 4, 117, 986,
                            779, 740, 58, 944, 883, 908, 457, 341, 1000, 224, 92, 375, 939, 792, 898, 978,
                            125, 412, 15, 986, 350, 120, 959, 316, 468, 690, 219, 262, 778, 348, 231, 271,
                            411, 389, 825, 756, 308, 309, 871, 339, 302, 866, 899, 55, 543, 677, 573, 83,
                            515, 505, 617, 953, 843, 209, 339, 436, 803, 514, 630, 533, 298, 340, 337, 249,
                            570, 643, 332, 669, 175, 438, 449, 790, 256, 703, 128, 670, 449, 17, 258, 900,
                            615, 106, 585, 663, 129, 22, 307, 226, 699, 910, 799, 132, 420, 406, 640, 505,
                            344, 158, 470, 923, 620, 910, 320, 395, 112, 873, 920, 700, 627, 911, 814, 698,
                            655, 136, 771, 303, 755, 339, 853, 295, 17, 544, 20, 137, 36, 791, 160, 526,
                            39, 486, 390, 357, 662, 934, 870, 591, 20, 728, 59, 705, 953, 664, 776, 739,
                            902, 132, 780, 744, 776, 837, 798, 679, 554, 555, 141, 68, 631, 735, 57, 147,
                            693, 456, 755, 312, 133, 494, 594, 986, 508, 198, 542, 195, 340, 728, 722, 834,
                            728, 1000, 461, 995, 424, 297, 128, 803, 575, 952, 982, 127, 244, 421, 224, 996,
                            307, 571, 45, 598, 662, 649, 867, 633, 691, 61, 613, 522, 466, 213, 47, 111,
                            590, 453, 581, 296, 717, 429, 773, 908, 322, 227, 809, 799, 290, 667, 997, 635,
                            306, 206, 23, 868, 719, 977, 49, 141, 924, 655, 532, 678, 785, 509, 805, 85,
                            275, 915, 24, 618, 488, 588, 871, 90, 999, 632, 156, 244, 810, 765, 276, 459,
                            213, 600, 131, 140, 929, 279, 984, 224, 990, 828, 570, 818, 107, 798, 595, 665,
                            845, 647, 417, 812, 210, 55, 934, 793, 814, 737, 804, 446, 721, 877, 824, 18,
                            814, 211, 564, 787, 947, 201, 31, 607, 669, 896, 412, 591, 735, 437, 108, 966,
                            55, 944, 103, 746, 256, 508, 693, 949, 538, 555, 132, 84, 69, 957, 627, 155,
                            278, 115, 565, 397, 367, 54, 841, 115, 392, 265, 635, 972, 187, 909, 390, 648,
                            640, 984, 205, 512, 202, 618, 815, 269, 492, 185, 121, 544, 243, 353, 194, 662,
                            933, 751, 950, 670, 255, 439, 355, 7, 288, 393, 405, 5, 327, 291, 10, 264,
                            308, 78, 877, 640, 937, 364, 148, 267, 776, 982, 16, 938, 127, 538, 873, 151,
                            856, 399, 812, 623, 264, 131, 703, 441, 395, 3, 849, 827, 816, 518, 646, 76,
                            406, 622, 312, 988, 392, 45, 266, 47, 420, 713, 284, 278, 205, 677, 87, 196,
                            254, 564, 918, 962, 761, 13, 142, 186, 114, 872, 304, 334, 825, 153, 16, 753,
                            185, 861, 284, 682, 425, 973, 326, 415, 537, 718, 798, 374, 221, 531, 399, 196,
                            773, 549, 518, 726, 483, 961, 274, 372, 394, 913, 803, 903, 280, 927, 270, 313,
                            797, 139, 827, 463, 485, 787, 593, 727, 860, 900, 264, 944, 962, 110, 771, 858,
                            832, 146, 479, 181, 228, 934, 74, 550, 59, 769, 485, 172, 906, 163, 315, 425,
                            473, 518, 503, 930, 616, 710, 896, 277, 354, 852, 145, 684, 462, 266, 102, 546,
                            812, 815, 710, 112, 621, 318, 943, 821, 752, 517, 446, 957, 57, 944, 437, 558,
                            267, 565, 873, 412, 253, 445, 268, 914, 666, 675, 941, 321, 685, 623, 605, 418,
                            201, 0, 183, 726, 175, 976, 416, 621, 587, 790, 874, 548, 181, 994, 712, 15,
                            88, 629, 805, 511, 259, 914, 762, 983, 675, 364, 56, 340, 203, 112, 297, 717,
                            891, 675, 977, 342, 210, 178, 477, 889, 396, 428, 319, 567, 217, 436, 733, 209,
                            251, 70, 897, 767, 915, 0, 906, 545, 588, 674, 673, 7, 366, 42, 749, 27,
                            3, 838, 2, 350, 898, 576, 176, 200, 77, 865, 957, 810, 28, 984, 927, 320,
                            861, 980, 646, 672, 653, 185, 803, 412, 757, 626, 306, 499, 827, 962, 756, 36,
                            896, 865, 617, 932, 282, 348, 838, 604, 981, 42, 0, 69, 716, 953, 80, 214,
                            341, 516, 112, 551, 560, 904, 935, 469, 572, 36, 827, 575, 913, 280, 765, 926,
                            975, 739, 570, 273, 48, 586, 331, 792, 781, 510, 117, 57, 718, 304, 768, 115,
                            179, 87, 838, 643, 794, 405, 662, 57, 320, 927, 908, 244, 776, 707, 659, 445,
                            589, 316, 723, 520, 77, 804, 876, 559, 159, 810, 411, 833, 544, 278, 427, 971,
                            279, 129, 560, 369, 388, 153, 553, 114, 436, 496, 238, 421, 485, 50, 262, 856,
                            600, 540, 541, 729, 634, 747, 304, 287, 411, 590, 828, 889, 60, 358, 427, 247,
                            873, 510, 762, 25, 767, 955, 554, 545, 12, 480, 786, 18, 981, 890, 655, 998,
                            716, 235, 213, 232, 211, 1, 826, 570, 20, 717, 169, 686, 233, 505, 388, 517,
                            621, 617, 407, 795, 346, 22, 482, 309, 953, 72, 565, 546, 805, 625, 782, 482,
                            694, 492, 991, 854, 718, 313, 182, 106, 285, 53, 627, 365, 597, 125, 140, 550,
                            943, 809, 68, 269, 572, 1000, 615, 15, 168, 559, 894, 352, 472, 150, 180, 792,
                            5, 838, 391, 725, 625, 467, 216, 489, 575, 547, 284, 896, 716, 106, 545, 28,
                            534, 226, 930, 837, 197, 804, 423, 993, 136, 545, 456, 890, 848, 739, 568, 548,
                            781, 760, 823, 385, 2, 800, 312, 771, 655, 870, 697, 500, 798, 396, 8, 253,
                            710, 369, 821, 146, 466, 591, 113, 584, 652, 899, 900, 870, 198, 378, 534, 832,
                            423, 540, 272, 713, 337, 500, 733, 786, 477, 443, 502, 647, 302, 251, 28, 657,
                            569, 213, 888, 919, 460, 52, 383, 254, 487, 21, 889, 195, 421, 137, 812, 637,
                            635, 928, 551, 7, 149, 322, 473, 530, 634, 801, 148, 994, 515, 594, 657, 760,
                            869, 680, 190, 418, 227, 743, 584, 318, 918, 385, 919, 891, 14, 134, 531, 2,
                            88, 376, 790, 777, 896, 959, 773, 728, 874, 119, 409, 714, 899, 173, 225, 238,
                            979, 19, 488, 213, 740, 995, 818, 162, 549, 100, 423, 796, 519, 164, 765, 0,
                            };

    complex_int16 signal_2 [512];

    
    int16_t alldata_3 [1024] = {897, 624, 866, 102, 551, 752, 605, 337, 791, 683, 121, 834, 554, 147, 970, 16,
                            885, 768, 673, 49, 407, 374, 301, 34, 253, 669, 89, 286, 37, 14, 203, 376,
                            194, 739, 375, 276, 874, 798, 206, 106, 196, 361, 995, 475, 843, 779, 591, 497,
                            909, 389, 77, 222, 35, 90, 635, 654, 602, 541, 968, 52, 755, 83, 498, 621,
                            500, 702, 129, 73, 919, 712, 967, 849, 68, 513, 409, 322, 405, 794, 522, 617,
                            633, 23, 237, 971, 963, 369, 310, 569, 483, 78, 34, 223, 863, 712, 19, 845,
                            794, 706, 75, 702, 44, 775, 140, 596, 992, 262, 936, 245, 450, 143, 732, 28,
                            371, 769, 155, 47, 314, 198, 208, 332, 796, 273, 512, 76, 705, 792, 101, 766,
                            263, 388, 804, 585, 43, 606, 110, 500, 34, 534, 879, 468, 815, 1, 572, 807,
                            341, 918, 891, 137, 16, 891, 480, 19, 511, 856, 882, 959, 135, 588, 206, 411,
                            933, 458, 695, 133, 509, 231, 505, 495, 721, 616, 619, 903, 866, 585, 217, 674,
                            713, 743, 891, 521, 44, 6, 382, 907, 597, 327, 843, 646, 165, 327, 866, 55,
                            424, 919, 758, 416, 156, 279, 330, 229, 448, 151, 479, 990, 831, 952, 314, 637,
                            11, 657, 305, 223, 218, 556, 122, 934, 355, 438, 677, 823, 328, 345, 695, 32,
                            453, 378, 590, 399, 798, 728, 119, 144, 1, 209, 366, 821, 565, 817, 638, 824,
                            523, 801, 916, 416, 740, 461, 538, 847, 606, 758, 163, 160, 288, 895, 578, 96,
                            587, 435, 7, 89, 128, 557, 647, 887, 498, 647, 553, 780, 222, 990, 460, 318,
                            952, 308, 548, 913, 749, 141, 488, 554, 539, 156, 889, 141, 46, 940, 918, 839,
                            609, 140, 812, 28, 851, 56, 370, 473, 556, 256, 502, 257, 695, 432, 535, 445,
                            296, 87, 248, 34, 75, 839, 590, 753, 544, 713, 419, 763, 983, 717, 990, 992,
                            538, 494, 970, 419, 953, 747, 209, 27, 914, 274, 972, 712, 217, 641, 148, 295,
                            869, 578, 606, 892, 845, 437, 807, 948, 118, 172, 605, 705, 746, 803, 167, 19,
                            816, 149, 968, 478, 683, 763, 236, 189, 656, 12, 750, 179, 863, 916, 500, 58,
                            568, 854, 235, 910, 731, 246, 755, 787, 691, 956, 500, 990, 366, 253, 86, 276,
                            107, 158, 83, 272, 264, 50, 639, 520, 981, 236, 312, 823, 816, 70, 513, 692,
                            310, 937, 142, 685, 404, 306, 803, 402, 895, 971, 151, 25, 961, 241, 529, 383,
                            896, 412, 787, 22, 769, 840, 432, 270, 713, 892, 877, 569, 391, 857, 450, 535,
                            499, 608, 953, 160, 749, 538, 521, 422, 536, 625, 469, 456, 350, 569, 907, 345,
                            458, 687, 43, 697, 540, 596, 186, 818, 584, 385, 178, 839, 970, 466, 40, 721,
                            746, 497, 243, 943, 613, 687, 192, 668, 170, 684, 900, 856, 760, 41, 904, 510,
                            679, 567, 991, 198, 217, 312, 880, 844, 773, 668, 644, 37, 142, 579, 253, 578,
                            20, 697, 345, 245, 49, 814, 372, 437, 509, 140, 130, 677, 260, 791, 290, 645,
                            435, 389, 650, 710, 74, 14, 629, 649, 285, 233, 100, 589, 127, 747, 818, 678,
                            621, 439, 743, 864, 828, 283, 895, 906, 85, 527, 942, 382, 272, 975, 692, 770,
                            946, 989, 884, 766, 218, 976, 443, 468, 501, 167, 751, 123, 737, 699, 611, 483,
                            760, 17, 367, 68, 207, 617, 789, 935, 812, 968, 45, 656, 284, 397, 204, 915,
                            217, 375, 738, 40, 116, 422, 716, 125, 240, 245, 992, 98, 941, 725, 89, 277,
                            256, 121, 626, 872, 683, 148, 900, 446, 999, 194, 362, 539, 455, 678, 237, 596,
                            908, 687, 430, 309, 409, 227, 232, 780, 818, 415, 327, 576, 223, 359, 599, 113,
                            34, 747, 708, 731, 459, 520, 296, 612, 324, 21, 198, 722, 897, 343, 715, 114,
                            709, 744, 245, 535, 804, 906, 622, 493, 100, 182, 622, 295, 127, 586, 862, 899,
                            597, 942, 824, 823, 823, 248, 913, 679, 167, 800, 585, 85, 639, 308, 359, 980,
                            659, 496, 448, 781, 742, 339, 303, 757, 70, 721, 867, 933, 643, 79, 576, 644,
                            731, 37, 204, 222, 975, 266, 424, 505, 501, 161, 912, 670, 997, 231, 864, 309,
                            12, 453, 453, 465, 893, 586, 89, 387, 229, 878, 566, 741, 243, 564, 838, 318,
                            625, 73, 247, 665, 244, 351, 855, 577, 402, 643, 729, 13, 737, 326, 751, 529,
                            327, 335, 159, 985, 430, 531, 583, 943, 258, 410, 543, 797, 821, 720, 736, 326,
                            71, 108, 939, 428, 790, 172, 325, 349, 190, 414, 518, 742, 420, 860, 52, 649,
                            469, 923, 64, 121, 151, 569, 474, 579, 702, 50, 215, 726, 898, 799, 568, 952,
                            718, 375, 290, 431, 764, 692, 568, 803, 673, 88, 524, 530, 117, 462, 59, 288,
                            442, 178, 704, 44, 410, 594, 155, 792, 434, 898, 13, 571, 436, 639, 254, 39,
                            973, 47, 498, 774, 110, 685, 335, 440, 888, 972, 76, 281, 528, 508, 136, 855,
                            426, 854, 839, 712, 559, 832, 974, 964, 229, 207, 510, 92, 582, 406, 939, 320,
                            98, 557, 376, 614, 528, 505, 445, 979, 303, 49, 710, 361, 971, 101, 550, 311,
                            710, 321, 890, 668, 713, 684, 685, 780, 258, 614, 416, 774, 87, 368, 457, 762,
                            455, 127, 463, 321, 590, 150, 999, 638, 429, 937, 204, 774, 977, 742, 439, 46,
                            114, 162, 822, 956, 354, 625, 679, 87, 479, 438, 152, 278, 317, 456, 902, 159,
                            743, 493, 758, 784, 188, 201, 689, 817, 279, 143, 702, 421, 781, 952, 21, 455,
                            102, 449, 453, 274, 885, 988, 763, 326, 595, 173, 249, 19, 338, 110, 222, 225,
                            984, 338, 953, 769, 630, 233, 345, 479, 363, 727, 373, 329, 435, 820, 916, 370,
                            303, 265, 439, 308, 630, 795, 460, 917, 997, 72, 178, 407, 817, 70, 554, 768,
                            827, 849, 384, 1000, 113, 414, 989, 331, 495, 180, 246, 952, 92, 630, 340, 735,
                            182, 954, 291, 693, 752, 168, 62, 727, 590, 517, 806, 471, 365, 480, 55, 586,
                            424, 25, 241, 590, 578, 295, 832, 939, 150, 130, 481, 968, 545, 791, 97, 568,
                            };

    complex_int16 signal_3 [512];

    
    asm volatile ("slti x0, x0, 1");
    asm volatile ("slti x0, x0, 3");
    //initialize

    
    for(int i = 0; i < 512; i++){
        complex_int16 temp = {alldata_0[(27*i)% 512 ] << Q, alldata_0[(23*i)% 512 ] << Q};
        signal_0[i] = temp;
    }
    
    for(int i = 0; i < 512; i++){
        complex_int16 temp = {alldata_1[(27*i)% 512 ] << Q, alldata_1[(23*i)% 512 ] << Q};
        signal_1[i] = temp;
    }
    
    for(int i = 0; i < 512; i++){
        complex_int16 temp = {alldata_2[(27*i)% 512 ] << Q, alldata_2[(23*i)% 512 ] << Q};
        signal_2[i] = temp;
    }
    
    for(int i = 0; i < 512; i++){
        complex_int16 temp = {alldata_3[(27*i)% 512 ] << Q, alldata_3[(23*i)% 512 ] << Q};
        signal_3[i] = temp;
    }
    
    
    
    fft(signal_0, 512, 9 );
    
    fft(signal_1, 512, 9 );
    
    fft(signal_2, 512, 9 );
    
    fft(signal_3, 512, 9 );
    
    
    asm volatile ("slti x0, x0, 4");
    asm volatile ("slti x0, x0, 2");
    return 0;
}