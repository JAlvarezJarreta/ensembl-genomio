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
"""Unit testing of :mod:`ensembl.io.genomio.genbank.download` module.

The unit testing is divided into one test class per submodule/class found in this module, and one test method
per public function/class method.

Typical usage example::
    $ pytest test_download.py

"""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock

from ensembl.io.genomio.genbank.download import download_genbank, DownloadError

@pytest.mark.parametrize(
        "accession",
        [
            ("CM023531.1"),
        ], 
    )
@patch('ensembl.io.genomio.genbank.download.requests.get')
class TestDownload:
    """Tests for the 'download_genbank' class"""
    
    def test_successful_download(self, mock_requests_get, tmp_dir: Path, accession):
        """Tests the successful download of 'download_genbank()' method.

        Args:
            tmp_dir: Session-scoped temporary directory fixture.
            accession: Genbank accession to be downloaded.
        """

        #Set success_code and content as an attribute to the mock object
        mock_requests_get.return_value.status_code = 200
        content = b"The genbank download for the following accession"
        mock_requests_get.return_value.content = content
        
        #Temporary location where we want to store the mock output file
        output_file = tmp_dir / f"{accession}.gb"
        download_genbank(accession, output_file)

        #checking if the url has been called
        mock_requests_get.assert_called_once_with(
            "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi",
            params={"db": "nuccore", "rettype": "gbwithparts", "retmode": "text", "id": accession},
            timeout=60
        )
        
        # Assert that the content was written to the temporary file
        with open(output_file, 'rb') as f:
            content = f.read()
        assert content == content

    def test_failed_download(self, mock_requests_failed, tmp_dir: Path, accession):
        """Tests the failure in downloading the files.

        Args:
            tmp_dir: Session-scoped temporary directory fixture.
            accession: Genbank accession to be downloaded.
        """

        output_file = tmp_dir / f"{accession}.gb"

        #Set the mock status code to 404 for request not found
        mock_requests_failed.return_value.status_code = 404

        #Raise an error 
        with pytest.raises(DownloadError, match='Could not download the genbank') as error:
            download_genbank(accession, output_file)
        