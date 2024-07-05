document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('cardForm');
    const preview = document.getElementById('cardPreview');
    const generatedUrl = document.getElementById('generatedUrl');
    const cardLink = document.getElementById('cardLink');
    const previewWrapper = document.getElementById('previewWrapper');

    function updatePreview() {
        const formData = new FormData(form);
        preview.innerHTML = `
            <h2>${formData.get('fname') || 'First'} ${formData.get('lname') || 'Last'}</h2>
            ${formData.get('pronouns') ? `<p>${formData.get('pronouns')}</p>` : ''}
            ${formData.get('title') ? `<p>${formData.get('title')}</p>` : ''}
            ${formData.get('biz') ? `<p>${formData.get('biz')}</p>` : ''}
            ${formData.get('addr') ? `<p>${formData.get('addr')}</p>` : ''}
            ${formData.get('desc') ? `<p>${formData.get('desc')}</p>` : ''}
        `;

        // Preview image uploads
        previewImage('logo');
        previewImage('cover');
        previewImage('photo');
    }

    function previewImage(fieldName) {
        const file = form[fieldName].files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = document.createElement('img');
                img.src = e.target.result;
                img.style.maxWidth = '100%';
                img.style.height = 'auto';
                preview.insertBefore(img, preview.firstChild);
            }
            reader.readAsDataURL(file);
        }
    }

    form.addEventListener('input', updatePreview);
    updatePreview(); // Initial preview

    form.addEventListener('submit', function(e) {
        e.preventDefault();
        const formData = new FormData(form);
        
        fetch('/create_card', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                cardLink.href = data.url;
                cardLink.textContent = data.url;
                generatedUrl.style.display = 'block';
                // Scroll to top of preview
                previewWrapper.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });

    // Ensure preview stays in view on mobile
    function adjustPreviewPosition() {
        if (window.innerWidth <= 768) {
            previewWrapper.style.position = 'static';
        } else {
            previewWrapper.style.position = 'sticky';
        }
    }

    window.addEventListener('resize', adjustPreviewPosition);
    adjustPreviewPosition(); // Initial call
});