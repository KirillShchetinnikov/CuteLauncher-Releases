"""Export a screen recording as H.264 MP4 with constant frame rate (PyAV).

Resamples frame timestamps without changing playback speed. No audio is copied;
this tool is intended for the silent landscape captures. Requires PyAV/libx264.
"""
import argparse
from fractions import Fraction
import hashlib
import json
import math
from pathlib import Path

import av


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--fps', type=int, default=24)
    args = parser.parse_args()
    if not 1 <= args.fps <= 120:
        parser.error('--fps must be between 1 and 120.')
    partial = args.output.with_name(args.output.stem + '.partial.mp4')
    report = args.output.with_suffix('.json')
    if any(p.exists() for p in [args.output, partial, report]):
        parser.error('Output already exists; choose a new filename.')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    tick = Fraction(1, args.fps)
    count = 0
    with av.open(str(args.source)) as source:
        video = source.streams.video[0]
        duration = (video.duration * video.time_base if video.duration is not None
                    else Fraction(source.duration, av.time_base))
        total = math.ceil(duration * args.fps)
        decoded = source.decode(video)
        previous = next(decoded)
        start = previous.pts * previous.time_base
        with av.open(str(partial), 'w', options={'movflags': '+faststart'}) as output:
            stream = output.add_stream('libx264', rate=args.fps)
            stream.width, stream.height = video.width, video.height
            stream.pix_fmt = 'yuv420p'
            stream.time_base = tick
            stream.codec_context.time_base = tick
            stream.options = {'crf': '18', 'preset': 'fast'}

            def emit(frame):
                nonlocal count
                image = frame.reformat(format='yuv420p')
                image.pts, image.time_base = count, tick
                for packet in stream.encode(image):
                    output.mux(packet)
                count += 1

            for frame in decoded:
                when = frame.pts * frame.time_base - start
                while count < total and count * tick < when:
                    emit(previous)
                previous = frame
            while count < total:
                emit(previous)
            for packet in stream.encode():
                output.mux(packet)

    # Verify every decoded output timestamp, not just the advertised frame rate.
    with av.open(str(partial)) as result:
        stream = result.streams.video[0]
        if stream.average_rate != args.fps:
            raise RuntimeError(f'Unexpected average frame rate: {stream.average_rate}')
        checked = 0
        for index, frame in enumerate(result.decode(stream)):
            if frame.pts * frame.time_base != index * tick:
                raise RuntimeError(f'Non-constant timestamp at frame {index}')
            checked += 1
        if checked != count:
            raise RuntimeError('Encoded/decoded frame count mismatch')
        details = {'file': args.output.name, 'source': str(args.source),
                   'codec': stream.codec_context.name, 'width': stream.width,
                   'height': stream.height, 'fps': args.fps, 'frames': count,
                   'duration_seconds': float(count * tick),
                   'source_duration_seconds': float(duration)}
    partial.rename(args.output)
    details['sha256'] = hashlib.sha256(args.output.read_bytes()).hexdigest()
    report.write_text(json.dumps(details, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(details, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
