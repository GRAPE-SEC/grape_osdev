# 2024~2025 Winter OSdev Project
OS 커널 개발을 시작할 수 있도록 도움을 주는 프로젝트입니다.

## 1. 진행 방식
- [<64비트 멀티코어 OS 원리와 구조 1권>](https://ebook-product.kyobobook.co.kr/dig/epd/ebook/E000003191795)을 주 레퍼런스로 진행합니다.
- 3장~10장을 다룹니다.
- 3장은 기초 이론 스터디를, 4장~10장은 코드 리뷰를 진행합니다.

## 2. Reference
- [Mint64 OS Github](https://github.com/kkamagui/mint64os)
- [Mint64 OS Community](https://jsandroidapp.cafe24.com/xe/)

## 3. Environment Setup
- Mint64 OS 개발 환경 구축을 위한 가이드라인입니다.
- 저자가 제공한 개발 환경 구축 최신 가이드라인은 [여기](https://github.com/kkamagui/mint64os-examples)를 클릭하세요.
- 아래의 가이드라인을 따라하면서, 위의 공식 가이드라인과 비교해 정상적으로 환경이 구축되는지 확인하세요.
- IDE는 원하는 도구를 사용하면 됩니다.

### 3.1. QEMU 다운로드
- 0.10.4 버전의 QEMU를 다운로드합니다.
  - [QEMU 0.10.4](https://kkamagui.tistory.com/764)

### 3.2. Cygwin 설치 & 실행
- Cygwin 설치
  - [setup-x86.exe](https://www.cygwin.com/setup-x86.exe)
- Cygwin 실행
  ```bat
  # cmd를 열고, setup_x86.exe가 위치한 디렉토리로 이동한 후 아래 명령을 실행하세요.
  cmd> .\setup-x86.exe --allow-unsupported-windows option --site http://ctm.crouchingtigerhiddenfruitbat.org/pub/cygwin/circa/2022/11/23/063457
  ```

### 3.3. Cygwin에서 패키지 설치
- Devel
  | Packages | Version |
  |----------|---------|
  | binutils | 2.37-2 with Src |
  | gcc-core | 7.4.0-1 with Src |
  | bison | 3.7.6-1 |
  | flex | 2.6.4-1 |
  | cygwin64-libiconv | 1.14-4 |
  | libtool | 2.4.6-7 |
  | make | 4.2.1-1 |
  | patchutils | 0.3.3-1 |
  | cygport | 0.35.2-1 |
  | nasm | 2.08.02-1 |
- Interpreters
  | Packages | Version |
  |----------|---------|
  | python2 | 2.7.18-4 |
- Libs
  | Packages | Version |
  |----------|---------|
  | libgmp-devel | 6.2.0-2 |
  | libmpfr-devel | 4.1.0-1 |
  | libmpc-devel | 1.2.0-1 |

### 3.4. Cygwin 환경변수 추가
- 시스템 변수: **PATH**
  - `C:\cygwin\bin;C:\cygwin\usr\cross\bin;`

### 3.5. binutils 크로스 컴파일
아래의 과정은 **Cygwin Terminal**에서 진행됩니다.
- binutils 소스코드 압축 해제
  ```bash
  $ cd /usr/src/binutils-2.37-2.src/
  $ cygport binutils-2.37-2.cygport prep
  ```
- 빌드 환경 설정
  ```bash
  $ cd binutils-2.37-2.i686/src/binutils-2.37
  $ export TARGET=x86_64-pc-linux
  $ export PREFIX=/usr/cross
  $ ./configure --target=$TARGET --prefix=$PREFIX --enable-64-bit-bfd --disable-shared --disable-nls --disable-unit-tests
  $ make configure-host
  ```
- 공유 라이브러리 이름 변경
  ```bash
  $ cp /lib/libmpfr.dll.a /lib/libmpfr.a
  $ cp /lib/libgmp.dll.a /lib/libgmp.a
  ```
- 빌드 및 설치
  ```bash
  # job 수는 빌드 환경을 고려햐여 적절히 설정해주세요.
  $ make LDFLAGS="-static" -j4
  $ make install
  ```
- 빌드 성공 확인
  ```bash
  $ /usr/cross/bin/x86_64-pc-linux-ld --help | grep "supported"
  ```

### 3.6. GCC 크로스 컴파일
- GCC 소스코드 압축 해제
  ```bash
  $ cd /usr/src/gcc-7.4.0-1.src
  $ cygport gcc.cygport prep
  ```
- 빌드 환경 설정
  ```bash
  $ cd gcc-7.4.0-1.i686/src/gcc-7.4.0/
  $ export TARGET=x86_64-pc-linux
  $ export PREFIX=/usr/cross
  $ export PATH=$PREFIX/bin:$PATH
  $ ./configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers --disable-shared --enable-multilib
  $ make configure-host -j8
  ```
- 공유 라이브러리 이름 변경
  ```bash
  $ cp /lib/gcc/i686-pc-cygwin/7.4.0/libgcc_s.dll.a /lib/gcc/i686-pc-cygwin/7.4.0/libgcc_s.a
  $ cp /lib/libmpc.dll.a /lib/libmpc.a
  ```
- 빌드 및 설치
  ```bash
  # job 수는 빌드 환경을 고려햐여 적절히 설정해주세요.
  $ make all-gcc -j4
  $ make install-gcc
  ```
- 빌드 성공 확인
  ```bash
  $ /usr/cross/bin/x86_64-pc-linux-gcc -dumpspecs | grep -A1 multilib_options
  ```
