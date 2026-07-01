FROM python:3.12-slim
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY store.py .
ENV PORT=8000
EXPOSE 8000
CMD ["python", "store.py"]
