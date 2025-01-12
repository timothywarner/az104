import PyPDF2
import os

def convert_pdf_to_text(pdf_path, output_path):
    try:
        # Open the PDF file
        with open(pdf_path, 'rb') as file:
            # Create a PDF reader object
            pdf_reader = PyPDF2.PdfReader(file)
            
            # Get the number of pages
            num_pages = len(pdf_reader.pages)
            
            # Extract text from each page
            with open(output_path, 'w', encoding='utf-8') as output_file:
                for page_num in range(num_pages):
                    # Get the page
                    page = pdf_reader.pages[page_num]
                    
                    # Extract text from the page
                    text = page.extract_text()
                    
                    # Write to output file with page number
                    output_file.write(f"\n--- Page {page_num + 1} ---\n")
                    output_file.write(text)
                    output_file.write("\n")
            
            print(f"Successfully converted {pdf_path} to {output_path}")
            print(f"Total pages processed: {num_pages}")
            
    except Exception as e:
        print(f"Error converting PDF: {str(e)}")

# Convert the CAF PDF
pdf_path = "azure-cloud-adoption-framework.pdf"
output_path = "azure-cloud-adoption-framework.txt"

if os.path.exists(pdf_path):
    convert_pdf_to_text(pdf_path, output_path)
else:
    print(f"PDF file not found at: {pdf_path}") 