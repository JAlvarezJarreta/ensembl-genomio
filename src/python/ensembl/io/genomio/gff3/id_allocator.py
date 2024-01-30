# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Check and allocate IDs for gene features in a GFF3 file."""

__all__ = ["IDAllocator"]

from dataclasses import dataclass
import logging
import re
from typing import List

from Bio.SeqFeature import SeqFeature


class InvalidID(ValueError):
    """Raised when there is a problem with an ID."""


@dataclass
class IDAllocator:
    """Set of tools to check and allocate stable ids."""

    # Multiple parameters to automate various fixes
    validate_gene_id = True
    min_id_length = 7
    current_id_number: int = 0
    make_missing_stable_ids: bool = True
    prefix = "TMP_"
    _loaded_ids: set = None

    def __init__(self) -> None:
        super().__init__()
        self._loaded_ids = set()

    def generate_id(self) -> str:
        """Returns a new unique gene stable_id with a prefix.

        The id is made up of a prefix and a number, which is auto incremented.
        Define the prefix with the param "id_prefix",

        """
        number = self.current_id_number + 1
        new_id = f"{self.prefix}{number}"
        self.current_id_number = number

        return new_id

    def valid_id(self, name: str) -> bool:
        """Check that the format of a stable id is valid."""

        if not self.validate_gene_id:
            return True

        # Trna (from tRNAscan)
        if re.search(r"^Trna", name, re.IGNORECASE):
            logging.debug(f"Stable ID is a tRNA from tRNA-scan: {name}")
            return False

        # Coordinates
        if re.search(r"^.+:\d+..\d+", name):
            logging.debug(f"Stable id is a coordinate: {name}")
            return False

        # Special characters
        if re.search(r"[ |]", name):
            logging.debug(f"Stable id contains special characters: {name}")
            return False

        # Min length
        if len(name) < self.min_id_length:
            logging.debug(f"Stable id is too short (<{self.min_id_length}) {name}")
            return False

        return True

    def remove_prefixes(self, identifier: str, prefixes: List[str]) -> str:
        """Returns the identifier after removing all the prefixes found in it (if any)."""
        for prefix in prefixes:
            if identifier.startswith(prefix):
                identifier = identifier[len(prefix) :]
                break
        return identifier

    def normalize_transcript_id(self, gene_id: str, number: int) -> str:
        """Use a gene ID and a number to make a formatted transcript ID."""

        transcript_id = f"{gene_id}_t{number}"
        return transcript_id

    def normalize_cds_id(self, cds_id: str) -> str:
        """Returns a normalised version of the provided CDS ID.

        The normalisation implies to remove any unnecessary prefixes around the CDS ID. However, if
        the CDS ID is still not proper, an empty string will be returned.

        """

        prefixes = ["cds-", "cds:"]
        cds_id = self.remove_prefixes(cds_id, prefixes)

        # Special case: if the ID doesn't look like one, remove it
        # It needs to be regenerated
        if not self.valid_id(cds_id):
            cds_id = ""

        return cds_id

    def normalize_pseudogene_cds_id(self, gene: SeqFeature) -> None:
        """Normalises the CDS ID of the provided pseudogene.

        Ensure CDS from a pseudogene have a proper ID:
        - Different from the gene
        - Derived from the gene if it is not proper

        """

        for transcript in gene.sub_features:
            for feat in transcript.sub_features:
                if feat.type == "CDS":
                    feat.id = self.normalize_cds_id(feat.id)
                    if feat.id in ("", gene.id):
                        feat.id = f"{transcript.id}_cds"
                        feat.qualifiers["ID"] = feat.id

    def normalize_gene_id(self, gene: SeqFeature) -> str:
        """Remove any unnecessary prefixes around the gene ID.

        Generate a new stable id if it is not recognized as valid.

        Args:
            gene: Gene feature to normalize.

        Returns:
            A normalized gene id.

        """

        prefixes = ["gene-", "gene:"]
        new_gene_id = self.remove_prefixes(gene.id, prefixes)

        # In case the gene id is not valid, use the GeneID
        if not self.valid_id(new_gene_id):
            logging.debug(f"Gene id is not valid: {new_gene_id}")
            qual = gene.qualifiers
            if "Dbxref" in qual:
                for xref in qual["Dbxref"]:
                    (db, value) = xref.split(":")
                    if db == "GeneID":
                        new_gene_id_base = f"{db}_{value}"
                        new_gene_id = new_gene_id_base
                        number = 1
                        while new_gene_id in self._loaded_ids:
                            number += 1
                            new_gene_id = f"{new_gene_id_base}_{number}"
                            if number > 10:
                                raise InvalidID(f"Duplicate ID {new_gene_id_base} (up to {new_gene_id})")
                        self._loaded_ids.add(new_gene_id)
                        logging.debug(f"Using GeneID {new_gene_id} for stable_id instead of {gene.id}")
                        return new_gene_id

            # Make a new stable_id
            if self.make_missing_stable_ids:
                new_id = self.generate_id()
                logging.debug(f"New id: {new_gene_id} -> {new_id}")
                return new_id
            raise InvalidID(f"Can't use invalid gene id for {gene}")

        return new_gene_id