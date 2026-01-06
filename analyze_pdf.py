import fitz  # PyMuPDF
import sys
import os

def analyze_pdf(pdf_path):
    print(f"Analyzing: {pdf_path}")
    if not os.path.exists(pdf_path):
        print("File not found!")
        return

    try:
        doc = fitz.open(pdf_path)
        print(f"Number of pages: {len(doc)}")
        
        all_text = ""
        image_count = 0
        
        for i, page in enumerate(doc):
            text = page.get_text()
            all_text += f"--- Page {i+1} ---\n{text}\n"
            
            # Check for images
            images = page.get_images(full=True)
            if images:
                image_count += len(images)
                print(f"Page {i+1} has {len(images)} images.")
                for img_index, img in enumerate(images):
                    xref = img[0]
                    base_image = doc.extract_image(xref)
                    image_bytes = base_image["image"]
                    image_ext = base_image["ext"]
                    image_filename = f"page{i+1}_img{img_index+1}.{image_ext}"
                    with open(image_filename, "wb") as img_file:
                        img_file.write(image_bytes)
                    print(f"Saved {image_filename}")

        print(f"\nTotal Text Length: {len(all_text)}")
        print(f"Total Images Found: {image_count}")
        
        with open("pdf_content.txt", "w", encoding="utf-8") as f:
            f.write(all_text)
            
        print("Text content saved to pdf_content.txt")
        
    except Exception as e:
        print(f"Error reading PDF: {e}")

if __name__ == "__main__":
    analyze_pdf(r"d:\rustdesk-master\rustdesk-master\易连助手.pdf")
