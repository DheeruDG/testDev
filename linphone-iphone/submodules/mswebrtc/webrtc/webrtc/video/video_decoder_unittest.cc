/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "webrtc/video_decoder.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "webrtc/base/checks.h"
#include "webrtc/modules/video_coding/codecs/interface/video_error_codes.h"

namespace webrtc {

class VideoDecoderSoftwareFallbackWrapperTest : public ::testing::Test {
 protected:
  VideoDecoderSoftwareFallbackWrapperTest()
      : fallback_wrapper_(kVideoCodecVP8, &fake_decoder_) {}

  class CountingFakeDecoder : public VideoDecoder {
   public:
    int32_t InitDecode(const VideoCodec* codec_settings,
                       int32_t number_of_cores) override {
      ++init_decode_count_;
      return WEBRTC_VIDEO_CODEC_OK;
    }

    int32_t Decode(const EncodedImage& input_image,
                   bool missing_frames,
                   const RTPFragmentationHeader* fragmentation,
                   const CodecSpecificInfo* codec_specific_info,
                   int64_t render_time_ms) override {
      ++decode_count_;
      return decode_return_code_;
    }

    int32_t RegisterDecodeCompleteCallback(
        DecodedImageCallback* callback) override {
      decode_complete_callback_ = callback;
      return WEBRTC_VIDEO_CODEC_OK;
    }

    int32_t Release() override {
      ++release_count_;
      return WEBRTC_VIDEO_CODEC_OK;
    }

    int32_t Reset() override {
      ++reset_count_;
      return WEBRTC_VIDEO_CODEC_OK;
    }
    int init_decode_count_ = 0;
    int decode_count_ = 0;
    int32_t decode_return_code_ = WEBRTC_VIDEO_CODEC_OK;
    DecodedImageCallback* decode_complete_callback_ = nullptr;
    int release_count_ = 0;
    int reset_count_ = 0;
  };
  CountingFakeDecoder fake_decoder_;
  VideoDecoderSoftwareFallbackWrapper fallback_wrapper_;
};

TEST_F(VideoDecoderSoftwareFallbackWrapperTest, InitializesDecoder) {
  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  EXPECT_EQ(1, fake_decoder_.init_decode_count_);
}

TEST_F(VideoDecoderSoftwareFallbackWrapperTest,
       CanRecoverFromSoftwareFallback) {
  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  // Unfortunately faking a VP8 frame is hard. Rely on no Decode -> using SW
  // decoder.
  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE;
  EncodedImage encoded_image;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(1, fake_decoder_.decode_count_);

  // Fail -> fake_decoder shouldn't be used anymore.
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(1, fake_decoder_.decode_count_)
      << "Decoder used even though fallback should be active.";

  // Should be able to recover on a keyframe.
  encoded_image._frameType = kVideoFrameKey;
  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_OK;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(2, fake_decoder_.decode_count_)
      << "Wrapper did not try to decode a keyframe using registered decoder.";

  encoded_image._frameType = kVideoFrameDelta;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(3, fake_decoder_.decode_count_)
      << "Decoder not used on future delta frames.";
}

TEST_F(VideoDecoderSoftwareFallbackWrapperTest, DoesNotFallbackOnEveryError) {
  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_ERROR;
  EncodedImage encoded_image;
  EXPECT_EQ(
      fake_decoder_.decode_return_code_,
      fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1));
  EXPECT_EQ(1, fake_decoder_.decode_count_);

  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(2, fake_decoder_.decode_count_)
      << "Decoder should be active even though previous decode failed.";
}

TEST_F(VideoDecoderSoftwareFallbackWrapperTest, ForwardsReleaseCall) {
  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  fallback_wrapper_.Release();
  EXPECT_EQ(1, fake_decoder_.release_count_);

  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE;
  EncodedImage encoded_image;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  EXPECT_EQ(1, fake_decoder_.release_count_)
      << "Decoder should not be released during fallback.";
  fallback_wrapper_.Release();
  EXPECT_EQ(2, fake_decoder_.release_count_);
}

TEST_F(VideoDecoderSoftwareFallbackWrapperTest, ForwardsResetCall) {
  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  fallback_wrapper_.Reset();
  EXPECT_EQ(1, fake_decoder_.reset_count_);

  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE;
  EncodedImage encoded_image;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  fallback_wrapper_.Reset();
  EXPECT_EQ(2, fake_decoder_.reset_count_)
      << "Reset not forwarded during fallback.";
}

// TODO(pbos): Fake a VP8 frame well enough to actually receive a callback from
// the software encoder.
TEST_F(VideoDecoderSoftwareFallbackWrapperTest,
       ForwardsRegisterDecodeCompleteCallback) {
  class FakeDecodedImageCallback : public DecodedImageCallback {
    int32_t Decoded(VideoFrame& decodedImage) override { return 0; }
    int32_t Decoded(
        webrtc::VideoFrame& decodedImage, int64_t decode_time_ms) override {
      RTC_NOTREACHED();
      return -1;
    }
  } callback, callback2;

  VideoCodec codec = {};
  fallback_wrapper_.InitDecode(&codec, 2);
  fallback_wrapper_.RegisterDecodeCompleteCallback(&callback);
  EXPECT_EQ(&callback, fake_decoder_.decode_complete_callback_);

  fake_decoder_.decode_return_code_ = WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE;
  EncodedImage encoded_image;
  fallback_wrapper_.Decode(encoded_image, false, nullptr, nullptr, -1);
  fallback_wrapper_.RegisterDecodeCompleteCallback(&callback2);
  EXPECT_EQ(&callback2, fake_decoder_.decode_complete_callback_);
}

}  // namespace webrtc
