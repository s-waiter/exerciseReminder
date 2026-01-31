import React from 'react';
import { motion } from 'framer-motion';
import { HelpCircle, Shield, Download, Coffee } from 'lucide-react';

const faqs = [
  {
    question: "安装时提示“Windows已保护你的电脑”怎么办？",
    answer: "这是因为软件没有购买昂贵的数字签名证书（每年需数千元）。我们的软件完全开源且安全。请点击“更多信息” -> “仍要运行”即可正常安装。这不会对您的电脑造成任何伤害。",
    icon: Shield
  },
  {
    question: "软件是免费的吗？会有广告吗？",
    answer: "DeskCare 承诺永久免费，并且没有任何弹窗广告。我们的初衷是为久坐人群提供一个纯净的健康提醒工具。",
    icon: Coffee
  },
  {
    question: "如何设置开机自启动？",
    answer: "在软件主界面（如上图所示）中间位置，打开“开机自启”开关即可。这样每次开机软件就会自动在后台运行，默默守护您的健康。",
    icon: Download
  },
  {
    question: "如果有紧急事务可以跳过休息吗？",
    answer: "可以。在强制休息提醒出现时，点击“跳过”按钮即可暂时取消本次休息，灵活应对紧急会议或游戏团战。但为了健康，建议不要频繁跳过。",
    icon: HelpCircle
  }
];

const FAQ = () => {
  return (
    <div id="faq" className="py-24 bg-slate-900 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">常见问题</h2>
          <p className="text-slate-400">解答您可能关心的疑问</p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {faqs.map((faq, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
              className="bg-slate-800/50 rounded-2xl p-6 border border-slate-700 hover:bg-slate-800 transition-colors"
            >
              <div className="flex items-start gap-4">
                <div className="p-3 bg-teal-500/10 rounded-lg">
                  <faq.icon className="w-6 h-6 text-teal-400" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-white mb-2">{faq.question}</h3>
                  <p className="text-slate-400 leading-relaxed text-sm">
                    {faq.answer}
                  </p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FAQ;
