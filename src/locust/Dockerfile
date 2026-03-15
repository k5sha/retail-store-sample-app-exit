FROM python:3.12-slim

WORKDIR /locust

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY locustfile.py .

EXPOSE 8089

ENTRYPOINT ["locust"]
CMD ["-f", "locustfile.py", "--host", "http://localhost:8888"]
