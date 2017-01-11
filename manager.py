# Copyright (C) 2017 Bohdan Khomtchouk and Kasra A. Vand
# This file is part of Matchmaker.

# -------------------------------------------------------------------------------------------

from similarity import main
from datetime import datetime

pre = datetime.now()
main()
print(datetime.now() - pre)
