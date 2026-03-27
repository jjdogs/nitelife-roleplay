import sys
from rembg import remove
from PIL import Image

input_path  = sys.argv[1]  # e.g. output/dnxprops_foo.webp
output_path = sys.argv[2]  # e.g. output/dnxprops_foo.png

input_image  = Image.open(input_path)
output_image = remove(input_image)
output_image.save(output_path, "PNG")
