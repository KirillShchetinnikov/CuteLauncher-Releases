"""Generate the offline city catalog from GeoNames CC BY 4.0 extracts."""

import argparse
import re
from difflib import SequenceMatcher
from pathlib import Path
from zipfile import ZipFile


RUSSIAN = re.compile(r"[А-Яа-яЁё][А-Яа-яЁё .’'‐-]*")
LATIN = re.compile(r"[A-Za-z][A-Za-z .’'‐-]*")
TRANSLITERATION = dict(zip(
    "абвгдеёжзийклмнопрстуфхцчшщъыьэюя",
    ("a", "b", "v", "g", "d", "e", "yo", "zh", "z", "i", "y", "k", "l", "m", "n",
     "o", "p", "r", "s", "t", "u", "f", "kh", "ts", "ch", "sh", "shch", "", "y",
     "", "e", "yu", "ya"),
))
COMMON_RUSSIAN_NAMES = {
    "498817": "Санкт-Петербург",
    "524901": "Москва",
}


def simplified(value):
    return re.sub("[^a-z]", "", value.lower())


def names(row):
    aliases = row[3].split(",")
    cyrillic = [name for name in aliases if RUSSIAN.fullmatch(name)]
    latin = simplified(row[2])

    def similarity(name):
        transliterated = "".join(TRANSLITERATION.get(char, char) for char in name.lower())
        return SequenceMatcher(None, latin, simplified(transliterated)).ratio()

    russian = COMMON_RUSSIAN_NAMES.get(row[0]) or max(cyrillic, key=similarity, default="")
    alternatives = dict.fromkeys((row[2], *cyrillic, *(name for name in aliases if LATIN.fullmatch(name))))
    for name in (row[1], russian, ""):
        alternatives.pop(name, None)
    return russian, "|".join(alternatives) or row[1]


def load_cities(path):
    with ZipFile(path) as archive:
        with archive.open("cities5000.txt") as source:
            for line in source:
                row = line.decode("utf-8").rstrip("\r\n").split("\t")
                if row[7] not in {"PPLH", "PPLQ", "PPLW", "PPLX"}:
                    yield row


def load_labels(directory):
    regions = {}
    with (directory / "admin1CodesASCII.txt").open(encoding="utf-8") as source:
        for line in source:
            code, name, *_ = line.split("\t")
            regions[code] = name
    countries = {}
    with (directory / "countryInfo.txt").open(encoding="utf-8") as source:
        for line in source:
            if line.strip() and not line.startswith("#"):
                code, _, _, _, name, *_ = line.split("\t")
                countries[code] = name
    return regions, countries


def select_cities(rows):
    ranked = sorted(rows, key=lambda row: (-int(row[14]), int(row[0])))
    for domestic in (True, False):
        group = [row for row in ranked if (row[8] == "RU") == domestic]
        capitals = {"PPLC", "PPLA"} if domestic else {"PPLC"}
        seats = [row for row in group if row[7] in capitals]
        others = [row for row in group if row[7] not in capitals]
        yield from (seats + others)[:1000]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cities_zip", type=Path, help="GeoNames cities5000.zip")
    parser.add_argument("labels_dir", type=Path, help="Directory with admin1CodesASCII.txt and countryInfo.txt")
    parser.add_argument("--output", type=Path, default=Path("assets/cities.tsv"))
    args = parser.parse_args()
    regions, countries = load_labels(args.labels_dir)
    with args.output.open("w", encoding="utf-8", newline="\n") as output:
        for row in select_cities(load_cities(args.cities_zip)):
            russian, aliases = names(row)
            country, admin_code = row[8], row[10]
            region = regions.get(f"{country}.{admin_code}", "")
            output.write("\t".join((
                row[1], russian, region, countries.get(country, country), country,
                row[4], row[5], aliases,
            )) + "\n")


if __name__ == "__main__":
    main()
