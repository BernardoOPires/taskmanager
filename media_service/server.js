const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const {
    S3Client,
    PutObjectCommand,
    GetObjectCommand
} = require('@aws-sdk/client-s3');

const app = express();
app.use(cors());
app.use(express.json({ limit: "10mb" }));

const upload = multer({ dest: 'uploads/' });

const BUCKET = "shopping-images";

const s3 = new S3Client({
    endpoint: "http://localhost:4566",
    region: "us-east-1",
    credentials: {
        accessKeyId: "test",
        secretAccessKey: "test"
    },
    forcePathStyle: true
});


app.post("/upload", upload.single("file"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "Nenhum arquivo enviado" });
        }

        console.log("📸 Arquivo recebido:", req.file.originalname);

        const filePath = req.file.path;
        const fileContent = fs.readFileSync(filePath);

        const key = `photo_${Date.now()}.jpg`;

        await s3.send(new PutObjectCommand({
            Bucket: BUCKET,
            Key: key,
            Body: fileContent,
            ContentType: "image/jpeg"
        }));

        fs.unlinkSync(filePath);

        res.json({ message: "Upload OK", key });
    } catch (err) {
        console.error("Erro no upload:", err);
        res.status(500).json({ error: "Erro ao enviar para S3" });
    }
});

app.post("/upload/base64", async (req, res) => {
    try {
        const { base64 } = req.body;

        if (!base64) {
            return res.status(400).json({ error: "base64 não enviado" });
        }

        const buffer = Buffer.from(base64, "base64");
        const key = `photo_${Date.now()}.jpg`;

        await s3.send(new PutObjectCommand({
            Bucket: BUCKET,
            Key: key,
            Body: buffer,
            ContentType: "image/jpeg"
        }));

        res.json({ message: "Upload OK", key });
    } catch (err) {
        console.error("Erro no upload base64:", err);
        res.status(500).json({ error: "Erro ao enviar base64 para S3" });
    }
});


app.get("/files/:key", async (req, res) => {
    try {
        const key = req.params.key;

        const data = await s3.send(new GetObjectCommand({
            Bucket: BUCKET,
            Key: key
        }));

        res.setHeader("Content-Type", "image/jpeg");

        data.Body.pipe(res);
    } catch (err) {
        console.error("Erro ao baixar imagem:", err);
        res.status(404).json({ error: "Arquivo não encontrado" });
    }
});



app.listen(3000, () => {
    console.log("Media Service rodando na porta 3000");
});
