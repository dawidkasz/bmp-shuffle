#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define MAX_IMG_SIZE 230455  // 320 x 240 x 3 + 55
#define BMP_HEADER_SIZE 54
#define BMP_HEADER_WIDTH 18
#define BMP_HEADER_HEIGHT 22


struct BMPInfo{
    char* filename;
    char* hdrData;
    char* imgData;
    u_int32_t width, height;
    u_int32_t linebytes;
};


void shuffleImage(struct BMPInfo *img, u_int32_t rows, u_int32_t cols);


void readBMP(char* buffer, FILE* fstream){
    int idx = 0;
    while (!feof(fstream)) {
        char c = fgetc(fstream);
        buffer[idx++] = c;
    }
}

void saveBMP(struct BMPInfo *img, char* buffer, FILE* fstream){
    u_int32_t imgSize = img->linebytes*img->height + BMP_HEADER_SIZE;
    fwrite(buffer, sizeof(buffer[0]), imgSize, fstream);
}


u_int32_t readDWord(char* buff, u_int32_t offset){
    u_int32_t x=0;
    x = 0xFF & buff[offset];
    x |= (0xFF & buff[offset+1]) << 8;
    x |= (0xFF & buff[offset+2]) << 16;
    x |= (u_int32_t)(0xFF & buff[offset+3]) << 24;

    return x;
}


void fillBMPInfo(struct BMPInfo *img, char* buff){
    img->width = readDWord(buff, BMP_HEADER_WIDTH);
    img->height = readDWord(buff, BMP_HEADER_HEIGHT);
    img->hdrData = buff;
    img->imgData = buff + BMP_HEADER_SIZE;
    img->linebytes = ((img->width * 3 + 3) / 4) * 4;
}


int main(int argc, char *argv[]){  // ./main [input.bmp] [rows] [cols] [output.bmp, default=result.bmp]
    srand(time(NULL));

    if(argc < 4){
        printf("Invalid command, expected `./main [input.bmp] [rows] [cols] [output.bmp, default=result.bmp]`\n");
        return 0;
    }

    struct BMPInfo* img = malloc(sizeof(struct BMPInfo));
    char buff[MAX_IMG_SIZE];

    img->filename = argv[1];
    u_int32_t rows = atoi(argv[2]);
    u_int32_t cols = atoi(argv[3]);

    char* ofname = "result.bmp";
    if(argc > 4)
        ofname = argv[4];

    FILE* fstream = fopen(img->filename, "rb");
    if(!fstream){
        printf("Can't open this file\n");
        return 0;
    }

    readBMP(buff, fstream);
    fclose(fstream);

    fillBMPInfo(img, buff);
    shuffleImage(img, rows, cols);

    fstream = fopen(ofname, "wb");
    saveBMP(img, buff, fstream);
    fclose(fstream);

    free(img);
    return 0;
}
