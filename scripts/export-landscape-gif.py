"""Export and verify a looping landscape GIF (FFmpeg + Pillow).

The README preset is 960x540, 12 fps, a video-specific 255-color palette,
Sierra dithering and changed-rectangle optimization. Input must be 16:9.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg'))
    parser.add_argument('--width', type=int, default=960)
    parser.add_argument('--fps', type=int, default=12)
    parser.add_argument('--expected-duration', type=float)
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error('Provide --ffmpeg or add FFmpeg to PATH.')
    if args.width <= 0 or args.width % 16 or not 1 <= args.fps <= 100:
        parser.error('Width must be a positive multiple of 16; fps must be 1..100.')
    partial = args.output.with_suffix('.partial.gif')
    palette = args.output.with_suffix('.palette.png')
    report = args.output.with_suffix('.json')
    if any(p.exists() for p in [args.output, partial, palette, report]):
        parser.error('Output files already exist; choose a new filename.')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    base = [args.ffmpeg, '-hide_banner', '-loglevel', 'error', '-nostdin']
    scale = f'fps={args.fps},scale={args.width}:-1:flags=lanczos'
    subprocess.run([*base, '-i', str(args.source), '-vf', scale + ',palettegen',
                    '-frames:v', '1', str(palette)], check=True)
    graph = f'[0:v]{scale}[v];[v][1:v]paletteuse=dither=sierra2_4a:diff_mode=rectangle'
    subprocess.run([*base, '-i', str(args.source), '-i', str(palette),
                    '-filter_complex_threads', '1', '-filter_complex', graph,
                    '-loop', '0', '-fps_mode', 'passthrough', str(partial)], check=True)
    with Image.open(partial) as gif:
        width, height = gif.size
        if (width, height) != (args.width, args.width * 9 // 16):
            raise RuntimeError(f'Expected 16:9; actual GIF size is {gif.size}')
        if gif.info.get('loop') != 0:
            raise RuntimeError('GIF does not loop forever')
        frames = gif.n_frames
        delays = []
        for index in range(frames):
            gif.seek(index)
            gif.load()
            delays.append(gif.info.get('duration', 0))
        if not all(value > 0 for value in delays):
            raise RuntimeError('GIF has a missing/non-positive frame delay')
        duration = sum(delays) / 1000
        if abs(frames / duration - args.fps) > .1:
            raise RuntimeError('GIF average frame rate differs from requested fps')
        if (args.expected_duration is not None
                and abs(duration - args.expected_duration) > 1 / args.fps + .02):
            raise RuntimeError('GIF playback duration differs from its source')
    partial.rename(args.output)
    details = {'file': args.output.name, 'source': str(args.source),
               'width': width, 'height': height, 'nominal_fps': args.fps,
               'average_fps': frames / duration, 'frames': frames,
               'duration_seconds': duration, 'frame_delays_ms': sorted(set(delays)),
               'loop': 0, 'dither': 'sierra2_4a', 'bytes': args.output.stat().st_size,
               'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest()}
    report.write_text(json.dumps(details, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(details, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
